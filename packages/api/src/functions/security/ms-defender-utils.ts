import { HttpRequest, InvocationContext } from '@azure/functions';

export function getMsDefenderUserJson(request: HttpRequest, conversationId: string, applicationName: string, context: InvocationContext): string {

    const sourceIp = request.headers.get('Remote-Addr') ?? "";
    const userId = request.headers.get('X-Ms-Client-Principal-Id');
    const authType = request.headers.get('X-Ms-Client-Principal-Idp');

    context.log("source ip: %s", sourceIp)
    context.log("conversation id: %s", conversationId)

    const userObject = {
        "EndUserId": userId,
        "EndUserIdType": authType == "aad" ? "EntraId" : authType,
        "SourceIp": sourceIp.split(':')[0],
        "SourceRequestHeaders": extractSpecificHeaders(request, context),
        "ConversationId": conversationId,
        "ApplicationName": applicationName,
    };

    return JSON.stringify(userObject);
}

function extractSpecificHeaders(request: HttpRequest, context: InvocationContext): any {
    const headerNames = ['User-Agent', 'X-Forwarded-For', 'Forwarded', 'X-Real-IP', 'True-Client-IP', 'CF-Connecting-IP'];
    var relevantHeaders = new Map<string, string>();

    request.headers.forEach((_, key) => context.log("Found header name %s", key));
    context.log("request headers: %s", JSON.stringify(request.headers.keys));

    for (const header of headerNames) {
        if (request.headers.has(header)) {
            context.log("found header: %s", header);
            relevantHeaders.set(header, request.headers.get(header)!);
        }
    }

    var entries = Object.fromEntries(relevantHeaders);
    context.log("found headers: %s", JSON.stringify(entries));
    return entries;
}
