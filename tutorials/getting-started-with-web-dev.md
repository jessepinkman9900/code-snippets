# Getting Started with Web Development (WIP)

Goal: build a rest api and deploy it to aws


1. Pick a language you are comfortable with - typescript
    1. pick a web dev framework - bun & nodejs
2. Build a simple GET /ping rest api that returns pong with http status 200
    1. test this with postman
    2. write a unit test for this API
3. Now building on your API service - lets add stateful REST API. meaning it needs to store data
    1. build a POST /counter/increment API that increments a counter in memory (we will upgrade it to use a database later)
        1. the response will be the updated value of the counter
        2. test it with postman
    2. you want to see counter value, you can always call the increment api so build a GET /counter API
        1. test it with postman
    3. test case
        1. run the api server
        2. run the POST /counter/increment API call
        3. restart the api server
        4. run the GET /counter API
        5. is the response as expected? why or why not
4. you have a decent API, you know how to run it on your laptop. how do you run it on your friends laptop without having to do a bunch of installations
    1. here comes in docker
    2. install docker
    3. manually write a dockerfile
        1. use a ubuntu (linux) base image
        2. install bun
        3. copy your codebase
        4. run the api server
    4. try to build your docker image
    5. run the docker image 
    6. test it using postman

