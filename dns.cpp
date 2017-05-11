/*****************************************************************************
*  Copyright 2005 Alt-N Technologies, Ltd.
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
*  This code incorporates intellectual property owned by Yahoo! and licensed
*  pursuant to the Yahoo! DomainKeys Patent License Agreement.
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*
*****************************************************************************/

#include <sys/types.h>
#include <ctype.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>

#include <stdio.h>
#include <string.h>

#include "dkim.h"
#include "dns.h"

static inline unsigned short getshort(unsigned char *cp) {
  return (cp[0] << 8) | cp[1];
}

////////////////////////////////////////////////////////////////////////////////
// 
// _DNSGetTXT for UNIX and win2k-
//
////////////////////////////////////////////////////////////////////////////////
int _DNSGetTXT( const char* szSubDomain, char* Buffer, int nBufLen )
{
  u_char answer[2*PACKETSZ+1];
  int answerlen;
  int ancount, qdcount;   /* answer count and query count */
  u_char *eom, *cp;
  u_short type, rdlength;   /* fields of records returned */
  int rc;
  char* bufptr;

  answerlen = res_query( szSubDomain, C_IN, T_TXT, answer, sizeof(answer));

  if( answerlen < 0 )
  {
    if( h_errno == TRY_AGAIN )
      return DNSRESP_TEMP_FAIL;
    else
      return DNSRESP_PERM_FAIL;
  }

	unsigned char rcode = answer[3] & 15;
	if (rcode != 0)
	{
		if (rcode == 3)
			return DNSRESP_NXDOMAIN;
		else
			return DNSRESP_PERM_FAIL;
	}

	qdcount = getshort( answer + 4); /* http://crynwr.com/rfc1035/rfc1035.html#4.1.1. */
	ancount = getshort( answer + 6);


	eom = answer + answerlen;
	cp  = answer + HFIXEDSZ;

	while( qdcount-- > 0 && cp < eom ) 
	{
		rc = dn_expand( answer, eom, cp, Buffer, nBufLen );
		if( rc < 0 ) {
			return DNSRESP_PERM_FAIL;
		}
		cp += rc + QFIXEDSZ;
	}

	while( ancount-- > 0 && cp < eom ) 
	{
		rc = dn_expand( answer, eom, cp, Buffer, nBufLen );
		if( rc < 0 ) {
			return DNSRESP_PERM_FAIL;
		}

		cp += rc;

		if (cp + RRFIXEDSZ >= eom) return DNSRESP_PERM_FAIL;

		type = getshort(cp + 0); /* http://crynwr.com/rfc1035/rfc1035.html#4.1.3. */
		rdlength = getshort(cp + 8);
		cp += RRFIXEDSZ;

		if( type != T_TXT ) {
			cp += rdlength;
			continue;
		}

		bufptr = Buffer;
		while (rdlength && cp < eom) 
		{
			int cnt;

			cnt = *cp++;		 /* http://crynwr.com/rfc1035/rfc1035.html#3.3.14. */
			if( bufptr-Buffer + cnt + 1 >= nBufLen )
				return DNSRESP_PERM_FAIL;
			if (cp + cnt > eom)
				return DNSRESP_PERM_FAIL;
			memcpy( bufptr, cp, cnt);
			rdlength -= cnt + 1;
			bufptr += cnt;
			cp += cnt;
			*bufptr = '\0';
		}

		return DNSRESP_SUCCESS;
	}

	return DNSRESP_EMPTY;
}


/* //////////////////////////////////////////////////////////////////////////////
 *
 * DNSGetTXT
 *
 * Pass in the FQDN to get the TXT record
 *
////////////////////////////////////////////////////////////////////////////// */
int DNSGetTXT( const char* szFQDN, char* Buffer, int nBufLen )
{
	if (strlen(szFQDN) > MAX_DOMAIN)
		return DNSRESP_DOMAIN_NAME_TOO_LONG;

	// Initialize out parameter
	Buffer[0] = '\0';

	return _DNSGetTXT( szFQDN, Buffer, nBufLen );
}
