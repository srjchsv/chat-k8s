## K8s manifests for a real-time chat app

Build using microservices architecture

![Real-Time Chat System Design](/chat.png "Real-Time Chat System Design")

## Stack

[Frontend](https://github.com/srjchsv/chat-frontend): Next js

Backend:
s
- [auth-service](https://github.com/srjchsv/auth-service): go, gin-gonic, prometheus, postgres, gorm, jwt
- [chat-service](https://github.com/srjchsv/chat-service): go, gin-gonic, prometheus, postgres, gorm, jwt, confluent-kafka, gorilla websocket
- [notifications-service](https://github.com/srjchsv/notifications-service): go, prometheus, echo, gorilla websocket, confluent-kafka
