import { AIChatMessage, AIChatCompletionDelta, AIChatProtocolClient, AIChatCompletion } from '@microsoft/ai-chat-protocol';

export const apiBaseUrl: string = import.meta.env.VITE_API_URL || '';

export type ChatRequestOptions = {
  messages: AIChatMessage[];
  chunkIntervalMs: number;
  apiUrl: string;
  stream: boolean;
};

export async function* getCompletion(options: ChatRequestOptions): Promise<AIChatCompletion> | AsyncGenerator<AIChatCompletionDelta> {
  const apiUrl = options.apiUrl || apiBaseUrl;
  const client = new AIChatProtocolClient(`${apiUrl}/api/chat`);

  if (options.stream) {
    const result = await client.getStreamedCompletion(options.messages);

    for await (const response of result) {
      if (!response.delta) {
        continue;
      }

      yield new Promise<AIChatCompletionDelta>((resolve) => {
        setTimeout(() => {
          resolve(response);
        }, options.chunkIntervalMs);
      });
    }
  } else {
    return await client.getCompletion(options.messages);
  }
}

export function getCitationUrl(citation: string): string {
  return `${apiBaseUrl}/api/documents/${citation}`;
}
