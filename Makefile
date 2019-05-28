ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
REGION:=us-east-1
PROFILE:=irdn
STACK_NAME:=baby2slack
REGPROF:=--profile ${PROFILE} --region ${REGION}
MAINPY:=${ROOT_DIR}/main.py
AMAINPYBODY=`cat ${MAINPY} | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\\\r\\\\n/g'`
MAINPYBODY=`awk -v ORS='\\\\n' '1' ${MAINPY}`
TEMPLATE_BODY_FILE:=${ROOT_DIR}/cloudformation.template
GENERATED_TEMPLATE_BODY_FILE:=${ROOT_DIR}/generated-cloudformation.template
TEMPLATE_BODY:=--template-body file://${GENERATED_TEMPLATE_BODY_FILE}


create-stack: generate-body
	aws cloudformation create-stack --stack-name ${STACK_NAME} ${TEMPLATE_BODY} \
		${REGPROF} \
		--parameters ParameterKey=SlackToken,ParameterValue=${SLACK_TOKEN},UsePreviousValue=false,ResolvedValue=${SLACK_TOKEN} \
		--capabilities CAPABILITY_IAM

update-stack: generate-body
	aws cloudformation update-stack --stack-name ${STACK_NAME} ${TEMPLATE_BODY} \
		${REGPROF} \
		--parameters ParameterKey=SlackToken,ParameterValue=${SLACK_TOKEN},UsePreviousValue=false,ResolvedValue=${SLACK_TOKEN} \
		--capabilities CAPABILITY_IAM

generate-body:
	cat ${TEMPLATE_BODY_FILE} | TEMPLATE_BODY_PLACEHOLDER=${MAINPYBODY} envsubst > ${GENERATED_TEMPLATE_BODY_FILE}

delete-stack:
	aws cloudformation delete-stack --stack-name ${STACK_NAME} ${REGPROF}

get-lambda:
	make extra="--query 'Stacks[0].Outputs[0].OutputValue'" describe-stack 

describe-stack:
	aws cloudformation describe-stacks ${REGPROF} --stack-name ${STACK_NAME} $(extra)
