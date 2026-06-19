# Dentix AI Chatbot

This module contains the AI chatbot system used in Dentix.

## Components

### 1. Booking Assistant
File: booking_assistant.py

Responsible for:
- Appointment booking.
- Slot management.
- Doctor and schedule extraction.

### 2. Knowledge Assistant
File: knowledge_assistant.py

Responsible for:
- Answering dental questions.
- Retrieving information using a RAG-based approach.

### 3. Combined Chatbot
File: combined_chatbot.py

The final chatbot integrates both booking and knowledge functionalities into one intelligent assistant.

## Knowledge Base

The folder `dentix_knowledge_db` contains the documents and vector database used by the chatbot.

## Supported Languages

- English
- Arabic
- Franco-Arabic