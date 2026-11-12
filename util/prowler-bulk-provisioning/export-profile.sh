#
# export aws credentials to be bulk-imported to prowler
# takes one profile name as parameter
# alternatively reads a list of profile names from ~/list-of-profiles
# (one profile name per line, e.g. sanitized output from awsume -l)
#
# Requirements: awsume (https://awsu.me/), aws cli >= 2.32.0
#

if [[ -z "$1" ]]; then
    echo "Give me a profile name as parameter. Try these:"
    alias awsume=". awsume"
    awsume -l
    exit;
fi

if [[ "$1" == "list" ]]; then
  if [[ -z "$2" ]]; then
      echo "Give me a list of profile names as second parameter."
      exit;
  fi
  if [ ! -f "$2" ]; then
      echo "File ${2} not found!"
      exit;
  fi

  # make a backup of last list first
  if [ -f "providers.yaml" ]; then
      cp "providers.yaml" "providers_$(date +%Y%m%d_%H%M%S).bak"
  fi
	echo "" > providers.yaml

	cat "$2" | while read line || [[ -n $line ]];
	do
	   ./export-profile.sh $line >> providers.yaml
	done
	exit
fi


# echo -n "\nAttempting to log in..."
aws login --profile "$1" || awsume "$1"

#$ aws sts get-caller-identity --profile example-infra
#{
#    "UserId": "AIxxxxxxx",
#    "Account": "123456789123",
#    "Arn": "arn:aws:iam::123456789123:user/doc"
#}
#
ACCOUNTID=`aws sts get-caller-identity --profile "$1" | jq '.Account'`


#aws configure export-credentials --profile example-infra --format process \
# | yq '{"access_key_id": .AccessKeyId, "secret_access_key": .SecretAccessKey, "session_token": .SessionToken}' \
# | yq -y
#
CREDS=`aws configure export-credentials --profile "$1"`
KEY=`echo $CREDS | jq '.AccessKeyId'`
SECRET=`echo $CREDS | jq '.SecretAccessKey'`
TOKEN=`echo $CREDS | jq '.SessionToken'`

# target format:
#- provider: aws
#  uid: "123456789132"
#  alias: "example-infra"
#  auth_method: credentials
#  credentials:

echo -n "
- provider: aws
  uid: "$ACCOUNTID"
  alias: "$1"
  auth_method: credentials
  credentials:
    access_key_id: "$KEY"
    secret_access_key: "$SECRET"
    session_token: "$TOKEN"
"
