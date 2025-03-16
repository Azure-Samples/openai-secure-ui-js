import process from 'node:process';
import { Readable } from 'node:stream';
import { DefaultAzureCredential, getBearerTokenProvider } from '@azure/identity';
import { type HttpRequest, type InvocationContext, type HttpResponseInit, app } from '@azure/functions';
import {
  type AIChatCompletionRequest,
  type AIChatCompletionDelta,
  type AIChatCompletion,
} from '@microsoft/ai-chat-protocol';
import { AzureOpenAI, OpenAI } from 'openai';
import 'dotenv/config';
import { type ChatCompletionChunk } from 'openai/resources';
import { getMsDefenderUserJson } from './security/ms-defender-utils.js';

const azureOpenAiScope = 'https://cognitiveservices.azure.com/.default';
const systemPrompt = `Assistant helps the user with cooking questions. Be brief in your answers. Answer only plain text, DO NOT use Markdown.

After your answer, ALWAYS generate 3 very brief follow-up questions that the user would likely ask next, based on the context.
Enclose the follow-up questions in double angle brackets. Example:
<<What ingredients I need to bake cookies?>>
<<What flavour can I use in my cookies?>>
<<How long should I put it in the oven?>>

Do no repeat questions that have already been asked.
Make sure the last question ends with ">>".
`;

export async function postChat(
  stream: boolean,
  request: HttpRequest,
  context: InvocationContext,
): Promise<HttpResponseInit> {
  try {
    const requestBody = (await request.json()) as AIChatCompletionRequest;
    const { messages } = requestBody;

    if (!messages || messages.length === 0 || !messages.at(-1)?.content) {
      return {
        status: 400,
        body: 'Invalid or missing messages in the request body',
      };
    }

    let model: string;
    let openai: OpenAI;

    if (process.env.OPENAI_API_KEY) {
      context.log('Using OpenAI API');
      model = process.env.OPENAI_MODEL_NAME || 'gpt-4o-mini';
      openai = new OpenAI();
    } else if (process.env.AZURE_OPENAI_API_DEPLOYMENT_NAME) {
      context.log('Using Azure OpenAI');
      model = process.env.AZURE_OPENAI_API_DEPLOYMENT_NAME;

      // Use the current user identity to authenticate.
      // No secrets needed, it uses `az login` or `azd auth login` locally,
      // and managed identity when deployed on Azure.
      const credentials = new DefaultAzureCredential();
      const azureADTokenProvider = getBearerTokenProvider(credentials, azureOpenAiScope);
      openai = new AzureOpenAI({ azureADTokenProvider });
    } else {
      throw new Error('No OpenAI API key or Azure OpenAI deployment provided');
    }

    let userContext: string | undefined;
    if (process.env.MS_DEFENDER_ENABLED) {
      userContext = getMsDefenderUserJson(request);
    }

    if (stream) {
      const responseStream = await openai.chat.completions.create({
        messages: [{ role: 'system', content: systemPrompt }, ...messages],
        temperature: 0.7,
        model,
        stream: true,
        user: userContext,
      });
      const jsonStream = Readable.from(createJsonStream(responseStream));

      return {
        headers: {
          'Content-Type': 'application/x-ndjson',
          'Transfer-Encoding': 'chunked',
        },
        body: jsonStream,
      };
    }

    const response = await openai.chat.completions.create({
      messages: [{ role: 'system', content: systemPrompt }, ...messages],
      temperature: 0.7,
      model,
      user: userContext,
    });

    return {
      jsonBody: {
        message: {
          content: response.choices[0].message.content,
          role: 'assistant',
        },
      } as AIChatCompletion,
    };
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
async function* createJsonStream(chunks: AsyncIterable<ChatCompletionChunk>) {
  for await (const chunk of chunks) {
    if (!chunk.choices[0]?.delta.content) continue;

    const responseChunk: AIChatCompletionDelta = {
      delta: {
        content: chunk.choices[0].delta.content,
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
