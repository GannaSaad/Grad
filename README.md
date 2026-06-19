# Dentix

AI-powered dental management platform combining clinic management, appointment scheduling, and intelligent assistance for both patients and dentists.

---

## Overview

Dentix is a cross-platform ecosystem developed as a graduation project. It integrates mobile and web technologies with Artificial Intelligence to improve dental workflows and patient experience.

---

## Core Modules

### Authentication & User Management

- Firebase Authentication
- Role-Based Access Control (RBAC)
- Patient
- Doctor
- Doctor Assistant
- Admin
- Management Staff
- Supplier

---

### Appointment Management

- Book appointments
- Reschedule appointments
- Cancel appointments
- Real-time slot availability
- Activity history
- Notifications

---

### Electronic Dental Records

- Patient profiles
- Medical history
- Treatment plans
- Clinical notes

---

### Inventory Management

- Material tracking
- Supply requests
- Stock monitoring

---

### Support Ticket System

- Clinic issue reporting
- Ticket management

---

## AI Components

### SHAGY Assistant (RAG Chatbot)

Supports:

- English
- Arabic
- Arabizi

Capabilities:

- Symptom understanding
- Dental specialty recommendation
- Conversational appointment booking
- Context-aware responses

---

### Speech-to-Text Module

Converts dentist-patient conversations into structured clinical notes.

Outputs:

- Complaint
- Symptoms
- Diagnosis
- Treatment Plan
- Clinical Notes

---

### Intraoral Image Analysis

Based on:

- ResNet-18

Capabilities:

- Dental condition classification
- Confidence score prediction
- Image-based clinical assistance

Dataset:

- Kaggle Intraoral Image Dataset

---

### No-Show Prediction

Machine Learning model using Logistic Regression.

Purpose:

- Predict missed appointments
- Assist administrators
- Reduce scheduling inefficiencies

---

## Backend

### Firebase Services

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Real-time synchronization

### API Services

- FastAPI

---

## Technologies

### Frontend

- Flutter

### Backend

- Firebase
- FastAPI

### Artificial Intelligence

- Python
- PyTorch
- Transformers
- FAISS
- Scikit-Learn
- Logistic Regression
- ResNet-18

---

## System Architecture

```text
Flutter App
     ↓
Firebase Backend
     ↓
Cloud Firestore
     ↓
AI Services
 ├── SHAGY Assistant
 ├── Speech-to-Text
 ├── Intraoral Analysis
 └── No-Show Prediction
```

---

## Features

- Multi-role system
- Real-time updates
- Conversational booking
- AI-powered assistance
- Dental image analysis
- Voice documentation
- Inventory management
- Support tickets
- Cross-platform deployment

---

## Project Structure

```text
Dentix
│
├── AI/
├── Datasets/
├── android/
├── ios/
├── lib/
├── web/
├── windows/
├── linux/
├── macos/
├── test/
├── assets/
├── pubspec.yaml
└── README.md
```

---

## Supported Platforms

- Android
- iOS
- Web
- Windows
- Linux
- macOS

---

## Database

Dentix uses Firebase as the primary backend infrastructure:

- Cloud Firestore (NoSQL Database)
- Firebase Authentication
- Firebase Storage
- Real-Time Listeners

---

## Main Workflows

### Patient Workflow

1. Register/Login
2. Describe symptoms
3. Receive AI assistance
4. Book appointments
5. View activities and medical history

### Doctor Workflow

1. Manage appointments
2. Access patient records
3. Upload intraoral images
4. Review AI recommendations
5. Document consultations using Speech-to-Text

### Admin Workflow

1. Manage users
2. Monitor platform activity
3. View No-Show predictions
4. Handle support tickets

---

## Technologies Stack

| Layer | Technologies |
|---------|-------------|
| Frontend | Flutter |
| Backend | Firebase, FastAPI |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication |
| Storage | Firebase Storage |
| AI Framework | PyTorch |
| Vector Search | FAISS |
| Machine Learning | Scikit-Learn |
| NLP | Transformers |
| Image Classification | ResNet-18 |

---

## Authors

Graduation Project - Nile University

Dentix Team

---

## License

This project is intended for academic and research purposes only.
