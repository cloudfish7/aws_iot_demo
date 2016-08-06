#! /bin/sh -e
# ----------------------------------------------------------
# AWS IoT demo用のセット作成
# ----------------------------------------------------------

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------
function usage() {
cat <<EOS
=======================================
【前提】
・AWS CLIがインストールされている。Access Key,Secret Keyが設定されていること
・jqがインストールされていること
【使い方】
第１引数：AWSアカウントID
第２引数：S3バケット名
=======================================
EOS
}

# ----------------------------------------------------------
# Const
# ----------------------------------------------------------
#REGION=ap-northeast-1
REGION=ap-southeast-1
TMP_DIR=tmp
THING_NAME=iot_demo
TOPIC_NAME=iot_device
IOT_ROLE_NAME=aws_iot_s3_role


# ----------------------------------------------------------
# Check
# ----------------------------------------------------------
aws --version &> /dev/null
if [ $? -eq 127 ] ; then
  echo aws cliをインストールしてください
fi
jq -V &> /dev/null
if [ $? -eq 127 ] ; then
  echo jqをインストールしてください
fi

# ----------------------------------------------------------
# Args 
# ----------------------------------------------------------
if [ $# -ne 2 ]; then
  usage
  exit
fi

aws_account_id=$1
s3_bucket_name=$2


# ----------------------------------------------------------
# Main Proc
# ----------------------------------------------------------
if [ ! -e ${TMP_DIR} ];then
   mkdir ${TMP_DIR}
fi

# ----------------------------------------------------------
# thing作成
# ----------------------------------------------------------
aws iot create-thing --region ${REGION} --thing-name ${THING_NAME}  >/dev/null

echo "create thing OK" 

# ----------------------------------------------------------
# 証明書作成
# ----------------------------------------------------------
aws iot create-keys-and-certificate --region ${REGION} --set-as-active > ${TMP_DIR}/certificate.json

cat ${TMP_DIR}/certificate.json | jq .keyPair.PublicKey -r > ${THING_NAME}_publickey.pem 
cat ${TMP_DIR}/certificate.json | jq .keyPair.PrivateKey -r > ${THING_NAME}_privatekey.pem

certificateId=`cat ${TMP_DIR}/certificate.json |jq -r .certificateId`
aws iot describe-certificate --region ${REGION} --certificate-id ${certificateId}  --output text --query certificateDescription.certificatePem > ${THING_NAME}_certificate.pem 

curl -s https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem -o rootCA.pem >/dev/null

echo "create certificate OK" 

# ----------------------------------------------------------
#policy作成
# ----------------------------------------------------------
cat << EOS > ${TMP_DIR}/${THING_NAME}_policy.json
{
    "Version": "2012-10-17", 
    "Statement": [{
        "Effect": "Allow",
        "Action":["iot:*"],
        "Resource": ["*"]
    }]
}
EOS

aws iot create-policy --region ${REGION} --policy-name ${THING_NAME}_policy --policy-document file://${TMP_DIR}/${THING_NAME}_policy.json >/dev/null 

echo "create iot policy OK" 

# ----------------------------------------------------------
#証明書の紐付け
# ----------------------------------------------------------
aws iot attach-thing-principal --region ${REGION} --thing-name ${THING_NAME} --principal "arn:aws:iot:${REGION}:${aws_account_id}:cert/${certificateId}" >/dev/null

# ----------------------------------------------------------
# Rule作成
# ----------------------------------------------------------
# Role作成
cat << EOS > ${TMP_DIR}/${THING_NAME}_role_policy.json
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${s3_bucket_name}/*"
    }
}
EOS

cat << EOS > ${TMP_DIR}/${THING_NAME}_role_ass.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal":{
         "Service":"iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOS

aws iam create-role --region ${REGION} --role-name ${IOT_ROLE_NAME} --assume-role-policy-document file://${TMP_DIR}/${THING_NAME}_role_ass.json >/dev/null 
aws  iam put-role-policy --region ${REGION} --role-name ${IOT_ROLE_NAME} --policy-name s3_put_policy --policy-document file://${TMP_DIR}/${THING_NAME}_role_policy.json >/dev/null 

# Rule作成
aws  iot create-topic-rule --region ${REGION} --generate-cli-skeleton >/dev/null 

cat << EOS > ${TMP_DIR}/${THING_NAME}_rule.json
{
    "ruleName": "iot_demo_rule",
    "topicRulePayload": {
        "sql": "SELECT * FROM '${TOPIC_NAME}'",
        "description": "iot demo",
        "actions": [

            {
                "s3": {
                    "roleArn": "string",
                    "roleArn" : "arn:aws:iam::${aws_account_id}:role/aws_iot_s3_role",
                    "bucketName": "string",
                    "key": "string"
                }
            }
        ],
        "ruleDisabled": false
    }
}
EOS

aws iot create-topic-rule --region ${REGION} --cli-input-json file://${TMP_DIR}/${THING_NAME}_rule.json >/dev/null
echo "create topic rule OK"

echo "Finish Create IoT Setting"
endpoint=`aws iot describe-endpoint --region ${REGION} |jq -r .endpointAddress`
echo "INFO ---------------------------------------------"
echo "aws iot endpoint ---------------------------------"
echo "${endpoint} "
echo "certificate --------------------------------------"
echo ${THING_NAME}_publickey.pem
echo ${THING_NAME}_privatekey.pem
echo ${THING_NAME}_certificate.pem
echo rootCA.pem
echo "--------------------------------------------------"

