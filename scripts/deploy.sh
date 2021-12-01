echo "Processing deploy.sh"
# Set EB BUCKET as env variable
EB_BUCKET=elasticbeanstalk-us-west-1-042047674537
# Set ECR REPO as env variable
ECR_REPO=042047674537.dkr.ecr.us-west-1.amazonaws.com/mm
# Set the default region for aws cli
aws configure set default.region us-west-1
# securely log in to ECR
eval $(aws ecr get-login --no-include-email --region us-west-1)
# Build docker image based on our default Dockerfile
docker build -t schnodevops2/mm .
# tag the image with the Travis-CI SHA
docker tag schnodevops2/mm:latest 042047674537.dkr.ecr.us-west-1.amazonaws.com/mm:$TRAVIS_COMMIT
# Push built image to ECS
docker push 042047674537.dkr.ecr.us-west-1.amazonaws.com/mm:$TRAVIS_COMMIT
# Use the linux sed command to replace the text '<VERSION>' in our Dockerrun file with the Travis-CI SHA
sed -i='' "s/<VERSION>/$TRAVIS_COMMIT/" Dockerrun.aws.json
# Zip up our modified Dockerrun with our .ebextensions directory
zip -r mm-prod-deploy.zip Dockerrun.aws.json .ebextensions
# verify contents of the zip file
unzip -l mm-prod-deploy.zip
# Upload zip file to s3 bucket
aws s3 cp mm-prod-deploy.zip s3://$EB_BUCKET/mm-prod-deploy.zip
# Create a new application version with new Dockerrun
aws elasticbeanstalk create-application-version --application-name megamarkets --version-label $TRAVIS_COMMIT --source-bundle S3Bucket=$EB_BUCKET,S3Key=mm-prod-deploy.zip
# Update environment to use new version number
aws elasticbeanstalk update-environment --environment-name megamarkets-prod --version-label $TRAVIS_COMMIT