import process from 'node:process';
import { HttpRequest } from '@azure/functions';

/**
 * Generates the user security context which contains several parameters that describe the AI application itself, and the end user that interacts with the AI application.
 * These fields assist your security operations teams to investigate and mitigate security incidents by providing a comprehensive approach to protecting your AI applications.
 * [Learn more](https://learn.microsoft.com/en-us/azure/defender-for-cloud/gain-end-user-context-ai) about protecting AI applications using Microsoft Defender for Cloud.
 * @param request - The HTTP request
 * @returns A json string which represents the user context
 */
export function getMsDefenderUserJson(request: HttpRequest): string {

    const sourceIp = getSourceIp(request);
    const authenticatedUserDetails = getAuthenticatedUserDetails(request);

    const userObject = {
        "EndUserTenantId": authenticatedUserDetails.get('tenantId'),
        "EndUserId": authenticatedUserDetails.get('userId'),
        "EndUserIdType": authenticatedUserDetails.get('identityProvider'),
        "SourceIp": sourceIp,
        "SourceRequestHeaders": extractSpecificHeaders(request),
        "ApplicationName": process.env.APPLICATION_NAME,
    };

    var userContextJsonString = JSON.stringify(userObject);
    return userContextJsonString;
}

function extractSpecificHeaders(request: HttpRequest): any {
    const headerNames = ['User-Agent', 'X-Forwarded-For', 'Forwarded', 'X-Real-IP', 'True-Client-IP', 'CF-Connecting-IP'];
    var relevantHeaders = new Map<string, string>();

    for (const header of headerNames) {
        if (request.headers.has(header)) {
            relevantHeaders.set(header, request.headers.get(header)!);
        }
    }

    return Object.fromEntries(relevantHeaders);
}

/**
 * Extracts user authentication details from the 'X-Ms-Client-Principal' header.
 * This is based on [Azure Static Web App documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/user-information)
 * @param request - The HTTP request
 * @returns A dictionary containing authentication details of the user
 */
function getAuthenticatedUserDetails(request: HttpRequest) : Map<string, string> {
    var authenticatedUserDetails = new Map<string, string>();
    var principalHeader = request.headers.get('X-Ms-Client-Principal');
    if (principalHeader == null) {
        return authenticatedUserDetails;
    }

    const principal = parsePrincipal(principalHeader);
    if (principal != null) {
        var idp = principal['identityProvider'] == "aad" ? "EntraId" : principal['identityProvider'];
        authenticatedUserDetails.set('identityProvider', idp);
    }

    if (principal['identityProvider'] == "aad") {
        // TODO: add only when userId represents actual IDP user id 
        // authenticatedUserDetails.set('userId', principal['userId']);
        if (process.env.AZURE_TENANT_ID != null) {
            authenticatedUserDetails.set('tenantId', process.env.AZURE_TENANT_ID);
        }
    }

    return authenticatedUserDetails
}

function parsePrincipal(principal : string | null) : any {
    if (principal == null) {
        return null;
    }

    try {
        return JSON.parse(Buffer.from(principal, 'base64').toString('utf-8'));
    } catch (error) {
        return null;
    }
}

function getSourceIp(request: HttpRequest) {
    const xForwardFor = request.headers.get('X-Forwarded-For');
    if (xForwardFor == null) {
        return null;
    }

    const ip = xForwardFor.split(',')[0];
    const colonIndex = ip.lastIndexOf(':');

    // case of ipv4
    if (colonIndex !== -1 && ip.indexOf(':') === colonIndex) {
        return ip.substring(0, colonIndex);
    }

    // case of ipv6
    if (ip.startsWith('[') && ip.includes(']:')) {
        return ip.substring(0, ip.indexOf(']:') + 1);
    }

    return ip;
}