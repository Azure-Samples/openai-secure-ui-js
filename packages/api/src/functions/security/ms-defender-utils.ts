import process from 'node:process';
import { type HttpRequest } from '@azure/functions';

/**
 * Generates the user security context which contains several parameters that describe the AI application itself, and the end user that interacts with the AI application.
 * These fields assist your security operations teams to investigate and mitigate security incidents by providing a comprehensive approach to protecting your AI applications.
 * [Learn more](https://learn.microsoft.com/azure/defender-for-cloud/gain-end-user-context-ai) about protecting AI applications using Microsoft Defender for Cloud.
 * @param request - The HTTP request
 * @returns A json string which represents the user context
 */
export function getMsDefenderUserJson(request: HttpRequest): UserSecurityContext {
  const sourceIp = getSourceIp(request);
  const authenticatedUserDetails = getAuthenticatedUserDetails(request);

  const userSecurityContext = {
    end_user_tenant_id: authenticatedUserDetails.get('tenantId'),
    end_user_id: authenticatedUserDetails.get('userId'),
    source_ip: sourceIp,
    application_name: process.env.APPLICATION_NAME,
  } as UserSecurityContext;

  return userSecurityContext;
}

/**
 * Extracts user authentication details from the 'X-Ms-Client-Principal' header.
 * This is based on [Azure Static Web App documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/user-information)
 * @param request - The HTTP request
 * @returns A dictionary containing authentication details of the user
 */
function getAuthenticatedUserDetails(request: HttpRequest): Map<string, string> {
  const authenticatedUserDetails = new Map<string, string>();
  const principalHeader = request.headers.get('X-Ms-Client-Principal');
  if (principalHeader === null) {
    return authenticatedUserDetails;
  }

  const principal = parsePrincipal(principalHeader);
  if (principal === null) {
    return authenticatedUserDetails;
  }

  const tenantId = process.env.AZURE_TENANT_ID;
  if (principal!.identityProvider === 'aad') {
    // TODO: add only when userId represents actual IDP user id
    // authenticatedUserDetails.set('userId', principal['userId']);
    authenticatedUserDetails.set('tenantId', tenantId!);
  }

  return authenticatedUserDetails;
}

function parsePrincipal(principal: string | undefined): Principal | undefined {
  if (principal === null) {
    return undefined;
  }

  try {
    return JSON.parse(Buffer.from(principal!, 'base64').toString('utf8')) as Principal;
  } catch {
    return undefined;
  }
}

function getSourceIp(request: HttpRequest) {
  const xForwardFor = request.headers.get('X-Forwarded-For');
  if (xForwardFor === null) {
    return null;
  }

  const ip = xForwardFor.split(',')[0];
  const colonIndex = ip.lastIndexOf(':');

  // Case of ipv4
  if (colonIndex !== -1 && ip.indexOf(':') === colonIndex) {
    return ip.slice(0, Math.max(0, colonIndex));
  }

  // Case of ipv6
  if (ip.startsWith('[') && ip.includes(']:')) {
    return ip.slice(0, Math.max(0, ip.indexOf(']:') + 1));
  }

  return ip;
}

type Principal = {
  identityProvider: string;
  userId: string;
};

export type UserSecurityContext = {
  application_name: string;
  end_user_id: string;
  end_user_tenant_id: string;
  source_ip: string;
};
