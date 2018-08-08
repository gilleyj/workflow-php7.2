#!/bin/sh
VAULT_DESTINATION="${VAULT_DESTINATION:-/app/.env}"
if [[ ! -z "${VAULT_URL}" && ! -z "${VAULT_KEY}"  && ! -z "${VAULT_SECRET}" ]]; then
	openssl=$(which openssl)
	if [[ -z "${openssl}" || ! -x ${openssl} ]] ; then
		echo "ERROR: openssl not found/not executable..."
		exit 1
	fi
	wget=$(which wget)
	if [[ -z "${wget}" || ! -x ${wget} ]] ; then
		echo "ERROR: wget not found/not executable..."
		exit 1
	fi
	mktemp=$(which mktemp)
	if [[ -z "${mktemp}" || ! -x ${mktemp} ]] ; then
		echo "ERROR: mktemp not found/not executable..."
		exit 1
	fi
	TEMP_FILE=$(${mktemp})
	echo "... ... sneak..."
	{
		${wget} -O ${TEMP_FILE} http://${VAULT_URL}/?=${VAULT_KEY}
		${openssl} aes-256-cbc -a -d -salt -in "${TEMP_FILE}" -out "${VAULT_DESTINATION}" -pass "pass:${VAULT_SECRET}"
	} 2>&1 > /dev/null
	rm ${TEMP_FILE}
else
	echo "... ... missing sneak info, sneak skipped..."
fi
