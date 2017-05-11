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
#define strnicmp strncasecmp 

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#include "dkim.h"
#include "dns.h"

// change these to your selector name, domain name, etc
#define MYSELECTOR	"default"
#define MYDOMAIN	"" //"bardenhagen.com"
#define MYIDENTITY	"" //"dkimtest@bardenhagen.com"

int DKIM_CALL SignThisHeader(const char* szHeader)
{
	if( strnicmp( szHeader, "X-", 2 ) == 0 )
	{
		return 0;
	}
	return 1;
}


int DKIM_CALL SelectorCallback(const char* szFQDN, char* szBuffer, int nBufLen )
{
	return 0;
}

void usage()
{
  char* version;
  version = (char *)DKIMVersion();
  printf("libqdkim %s \n",version);
  printf("Usage: libqdkim [-h|-v|-s] [tags] <msgfile> [<privkeyfile> <outfile>]\n\n");
  printf( "Options:\n\t-h show this help\n");
  printf( "\t-s sign the message\n");
  printf( "\t-v verify the message\n\n");
  printf( "These tags are available:\n");
  printf( "\t-b<standard>         - set the standard (1=allman, 2=ietf, 3=both)\n");
  printf( "\t-c<canonicalization> - r=relaxed [DEFAULT], s=simple, t=relaxed/simple, u=simple/relaxed\n");
  printf( "\t-d<domain>           - domain tag (if not provided it will be determined from the sender/from header)\n");
  printf( "\t-i<identity>         - the identity, usually the sender address (optional)\n");
  printf( "\t-l                   - include body length tag (optional)\n");
  printf( "\t-q                   - include query method tag\n");
  printf( "\t-t                   - include a timestamp tag (optional)\n");
  printf( "\t-x<expire_time>      - the expire time in seconds since epoch (optional, DEFAULT = current time + 604800)\n");
  printf( "\t-y<selector>         - set selector (DEFAULT: default)\n");
  printf( "\t-z<hash>             - set rsa-key type (1=sha1, 2=sha256, 3=both)\n");
}
int main(int argc, char* argv[])
{
  int n;
  const char* PrivKeyFile = "test.pem";
  const char* MsgFile = "test.msg";
  const char* OutFile = "signed.msg";
  int nPrivKeyLen;
  char PrivKey[2048];
  char Buffer[1024];
  int BufLen;
  char szSignature[10024];
  time_t t;
  DKIMContext ctxt;
  DKIMSignOptions opts = {0};

  opts.nHash = DKIM_HASH_SHA1_AND_256;

  time(&t);

  opts.nCanon = DKIM_SIGN_RELAXED;
  opts.nIncludeBodyLengthTag = 0;
  opts.nIncludeQueryMethod = 0;
  opts.nIncludeTimeStamp = 0;
  opts.expireTime = t + 604800;		// expires in 1 week
  strcpy( opts.szSelector, MYSELECTOR );
  strcpy( opts.szDomain, MYDOMAIN );
  strcpy( opts.szIdentity, MYIDENTITY );
  opts.pfnHeaderCallback = SignThisHeader;
  strcpy( opts.szRequiredHeaders, "NonExistant" );
  opts.nIncludeCopiedHeaders = 0;
  opts.nIncludeBodyHash = DKIM_BODYHASH_BOTH;

  int nArgParseState = 0;
  bool bSign = true;

  if(argc<2){
    usage();
    exit(1);
  }

	for( n = 1; n < argc; n++ )
	{
		if( argv[n][0] == '-' && strlen(argv[n]) > 1 )
		{
			switch( argv[n][1] )
			{
			case 'b':		// allman or ietf draft 1 or both
				opts.nIncludeBodyHash = atoi( &argv[n][2] );
				break;

			case 'c':		// canonicalization
				if( argv[n][2] == 'r' )
				{
					opts.nCanon = DKIM_SIGN_RELAXED;
				}
				else if( argv[n][2] == 's' )
				{
					opts.nCanon = DKIM_SIGN_SIMPLE;
				}
				else if( argv[n][2] == 't' )
				{
					opts.nCanon = DKIM_SIGN_RELAXED_SIMPLE;
//printf("c: %l",opts.nCanon);
//exit(1);
				}
				else if( argv[n][2] == 'u' )
				{
					opts.nCanon = DKIM_SIGN_SIMPLE_RELAXED;
				}
				break;

			case 'd': 
				strncpy(opts.szDomain,(const char*)(argv[n]+2),sizeof(opts.szDomain)-1);
				break;
			case 'l':		// body length tag
				opts.nIncludeBodyLengthTag = 1;
				break;


			case 'h':
				usage();
				return 0;

			case 'i':		// identity 
				if( argv[n][2] == '-' )
				{
					opts.szIdentity[0] = '\0';
				}
				else
				{
					strncpy( opts.szIdentity, argv[n] + 2,sizeof(opts.szIdentity)-1 );
				}
				break;

			case 'q':		// query method tag
				opts.nIncludeQueryMethod = 1;
				break;

			case 's':		// sign
				bSign = true;
				break;

			case 't':		// timestamp tag
				opts.nIncludeTimeStamp = 1;
				break;

			case 'v':		// verify
				bSign = false;
				break;

			case 'x':		// expire time 
				if( argv[n][2] == '-' )
				{
					opts.expireTime = 0;
				}
				else
				{
					opts.expireTime = t + atoi( argv[n] + 2  );
				}
				break;

			case 'y':
				strncpy( opts.szSelector, argv[n]+2, sizeof(opts.szSelector)-1);
				break;

			case 'z':		// sign w/ sha1, sha256 or both 
				opts.nHash = atoi( &argv[n][2] );
				break;
			}
		}
		else
		{
			switch( nArgParseState )
			{
			case 0:
				MsgFile = argv[n];
				break;
			case 1:
				PrivKeyFile = argv[n];
				break;
			case 2:
				OutFile = argv[n];
				break;
			}
			nArgParseState++;
		}
	}


	if( bSign )
	{
		FILE* PrivKeyFP = fopen( PrivKeyFile, "r" );

		if ( PrivKeyFP == NULL )
		{
		  printf( "libqdkim: can't open private key file %s\n", PrivKeyFile );
		  exit(1);
		}
		nPrivKeyLen = fread( PrivKey, 1, sizeof(PrivKey), PrivKeyFP );
		if (nPrivKeyLen == sizeof(PrivKey)) { /* TC9 */
		  printf( "libqdkim: private key buffer isn't big enough, use a smaller private key or recompile.\n");
		  exit(1);
		}
		PrivKey[nPrivKeyLen] = '\0';
		fclose(PrivKeyFP);


		FILE* MsgFP = fopen( MsgFile, "rb" );

		if ( MsgFP == NULL ) 
		{
			printf( "libqdkim: can't open msg file %s\n", MsgFile );
			exit(1);
		}

		n = DKIMSignInit( &ctxt, &opts );

		while (1) {

			BufLen = fread( Buffer, 1, sizeof(Buffer), MsgFP );

			if( BufLen > 0 )
			{
				DKIMSignProcess( &ctxt, Buffer, BufLen );
			}
			else
			{
				break;
			}
		}

		fclose( MsgFP );

		//n = DKIMSignGetSig( &ctxt, PrivKey, szSignature, sizeof(szSignature) );

		char* pSig = NULL;

		n = DKIMSignGetSig2( &ctxt, PrivKey, &pSig );

		strcpy( szSignature, pSig );

		DKIMSignFree( &ctxt );

		FILE* in = fopen( MsgFile, "rb" );
		FILE* out = fopen( OutFile, "wb+" );

		fwrite( szSignature, 1, strlen(szSignature), out );
		fwrite( "\r\n", 1, 2, out );

		while (1) {
			BufLen = fread( Buffer, 1, sizeof(Buffer), in );
			if( BufLen > 0 )
			{
				fwrite( Buffer, 1, BufLen, out );
			}
			else
			{
				break;
			}
		}

		fclose( in );
	}
	else
	{
		FILE* in = fopen( MsgFile, "rb" );

		DKIMVerifyOptions vopts = {0};
		vopts.pfnSelectorCallback = NULL; //SelectorCallback;

		n = DKIMVerifyInit( &ctxt, &vopts );

		while (1) {
			
			BufLen = fread( Buffer, 1, sizeof(Buffer), in );

			if( BufLen > 0 )
			{
				DKIMVerifyProcess( &ctxt, Buffer, BufLen );
			}
			else
			{
				break;
			}
		}

		n = DKIMVerifyResults( &ctxt );

		int nSigCount = 0;
		DKIMVerifyDetails* pDetails;
		char szPolicy[512];

		n = DKIMVerifyGetDetails(&ctxt, &nSigCount, &pDetails, szPolicy );

		for ( int i = 0; i < nSigCount; i++)
		{
			printf( "Signature #%d: ", i + 1 );

			if( pDetails[i].nResult >= 0 )
				printf( "Success\n" );
			else {
				printf( "Failure" );
			int e;
			e = pDetails[i].nResult;
//			printf("Details: %i, Policy: %s\n", pDetails->nResult, d);
//			printf(" (Code %i)\n", e);
			printf(" %i\n", e);
			}
		}
		DKIMVerifyFree( &ctxt );
	}

  return 0;
}
