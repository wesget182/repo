# start FROM a base layer of node v10.15
FROM node:10.15

# Set up a WORKDIR for application in the container
WORKDIR /usr/src/app

# copy all of your application files to the WORKDIR in the container
COPY . /usr/src/app/

# npm install to create node_modules in the container
RUN npm install

# build for production
RUN npm run build

# EXPOSE your server port
EXPOSE 3000

# run the server
ENTRYPOINT ["node", "server/server.js"]