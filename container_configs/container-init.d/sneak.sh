#!/bin/sh
VAULT_DESTINATION="${VAULT_DESTINATION:-/app/.env}"
if [[ ! -z "${VAULT_URL}" && ! -z "${VAULT_SECRET}" ]]; then
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
	if [[ ! -z "${VAULT_KEY}" ]] ; then
		URL="http://${VAULT_URL}/?=${VAULT_KEY}"
	else
		URL="http://${VAULT_URL}"
	fi
	echo "... ... sneak..."
	if [[ ! -z "${VAULT_BUGLY}" ]] ; then
		echo "... ... ... ${wget} -O ${TEMP_FILE} ${URL}"
		echo "... ... ... ${openssl} aes-256-cbc -a -d -salt -in \"${TEMP_FILE}\" -out \"${VAULT_DESTINATION}\" -pass \"pass:${VAULT_SECRET}\""
	fi

	${wget} -O ${TEMP_FILE} ${URL} &> /dev/null
	result=$?
	if [[ "$result" -eq "0" ]]; then
		${openssl} aes-256-cbc -a -d -salt -in "${TEMP_FILE}" -out "${VAULT_DESTINATION}" -pass "pass:${VAULT_SECRET}" &> /dev/null
		result=$?
		if [[ "$result" -eq "0" ]]; then
			echo "... ... found secret"
		fi
	else
		echo "... ... no secret"
	fi

	rm ${TEMP_FILE}
else
	echo "... ... missing sneak info, sneak skipped..."
fi
