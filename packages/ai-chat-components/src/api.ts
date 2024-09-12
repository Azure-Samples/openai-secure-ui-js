import {
  AIChatMessage,
  AIChatCompletionDelta,
  AIChatProtocolClient,
  AIChatCompletion,
} from '@microsoft/ai-chat-protocol';

export const apiBaseUrl: string = import.meta.env.VITE_BACKEND_API_URI || '';

export type ChatRequestOptions = {
  messages: AIChatMessage[];
  chunkIntervalMs: number;
  apiUrl: string;
  stream: boolean;
};

export async function getCompletion(
  options: ChatRequestOptions,
): Promise<AIChatCompletion | AsyncGenerator<AIChatCompletionDelta>> {
  const apiUrl = options.apiUrl || apiBaseUrl;
  const client = new AIChatProtocolClient(`${apiUrl}/api/chat`);

  if (options.stream) {
    const response = await client.getStreamedCompletion(options.messages);
    return getChunksFromResponse(response, options.chunkIntervalMs);
  } else {
    return await client.getCompletion(options.messages);
  }
}

export function getCitationUrl(citation: string): string {
  return `${apiBaseUrl}/api/documents/${citation}`;
}

export async function* getChunksFromResponse(
  response: AsyncIterable<AIChatCompletionDelta>,
  intervalMs: number,
): AsyncGenerator<AIChatCompletionDelta> {
  for await (const chunk of response) {
    if (!chunk.delta) {
      continue;
    }

    yield new Promise<AIChatCompletionDelta>((resolve) => {
      setTimeout(() => {
        resolve(chunk);
      }, intervalMs);
    });
  }
}
