import process from 'node:process';
import { Readable } from 'node:stream';
import { DefaultAzureCredential, getBearerTokenProvider } from '@azure/identity';
import { HttpRequest, InvocationContext, HttpResponseInit, app } from '@azure/functions';
import { AIChatCompletionRequest, AIChatCompletionDelta, AIChatCompletion } from '@microsoft/ai-chat-protocol';
import { AzureChatOpenAI } from '@langchain/openai';
import { ChatPromptTemplate } from '@langchain/core/prompts';
import 'dotenv/config';

const azureOpenAiScope = 'https://cognitiveservices.azure.com/.default';
const systemPrompt = `Assistant helps the user with cooking questions. Be brief in your answers. Answer only plain text, DO NOT use Markdown.

Generate 3 very brief follow-up questions that the user would likely ask next, based on the context.
Enclose the follow-up questions in double angle brackets. Example:
<<What ingredients I need to bake cookies?>>
<<What flavour can I use in my cookies?>>
<<How long should I put it in the oven?>>

Do no repeat questions that have already been asked.
Make sure the last question ends with ">>".
`;

export async function postChat(stream: boolean, request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  const azureOpenAiEndpoint = process.env.AZURE_OPENAI_API_ENDPOINT || 'http://localhost:4041';

  try {
    const requestBody = (await request.json()) as AIChatCompletionRequest;
    const { messages } = requestBody;

    if (!messages || messages.length === 0 || !messages.at(-1)?.content) {
      return {
        status: 400,
        body: 'Invalid or missing messages in the request body',
      };
    }

    let azureADTokenProvider: () => Promise<string> = async () => '__fake_token__';

    if (!azureOpenAiEndpoint.startsWith('http://localhost')) {
      // Use the current user identity to authenticate.
      // No secrets needed, it uses `az login` or `azd auth login` locally,
      // and managed identity when deployed on Azure.
      const credentials = new DefaultAzureCredential();
      azureADTokenProvider = getBearerTokenProvider(credentials, azureOpenAiScope);
    }

    const model = new AzureChatOpenAI({
      // Controls randomness. 0 = deterministic, 1 = maximum randomness
      temperature: 0.7,
      azureADTokenProvider,
    });

    const lastUserMessage = messages.at(-1)!.content;
    const prompt = ChatPromptTemplate.fromMessages([
      ['system', systemPrompt],
      ['human', '{input}'],
    ]);

    if (stream) {
      const responseStream = await prompt.pipe(model).stream({ input: lastUserMessage });
      const jsonStream = Readable.from(createJsonStream(responseStream as any));

      return {
        headers: {
          'Content-Type': 'application/x-ndjson',
          'Transfer-Encoding': 'chunked',
        },
        body: jsonStream,
      };
    } else {
      const response = await prompt.pipe(model).invoke({ input: lastUserMessage });

      return {
        jsonBody: {
          message: {
            content: response.content,
            role: 'assistant',
          },
        } as AIChatCompletion,
      };
    }
  } catch (_error: unknown) {
    const error = _error as Error;
    context.error(`Error when processing chat-post request: ${error.message}`);

    return {
      status: 500,
      body: 'Service temporarily unavailable. Please try again later.',
    };
  }
}

// Transform the response chunks into a JSON stream
async function* createJsonStream(chunks: AsyncIterable<{ content: string }>) {
  for await (const chunk of chunks) {
    if (!chunk.content) continue;

    const responseChunk: AIChatCompletionDelta = {
      delta: {
        content: chunk.content,
        role: 'assistant',
      },
    };

    // Format response chunks in Newline delimited JSON
    // see https://github.com/ndjson/ndjson-spec
    yield JSON.stringify(responseChunk) + '\n';
  }
}

app.setup({ enableHttpStream: true });
app.http('chat-stream-post', {
  route: 'chat/stream',
  methods: ['POST'],
  authLevel: 'anonymous',
  handler: postChat.bind(null, true),
});
app.http('chat-post', {
  route: 'chat',
  methods: ['POST'],
  authLevel: 'anonymous',
  handler: postChat.bind(null, false),
});
