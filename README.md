<div align="center">

# MY_CSE

**AI 기반 경상국립대학교 컴퓨터공학부 통합 공지 앱**

![Flutter](https://img.shields.io/badge/Flutter-315B89?style=flat-square) ![Dart](https://img.shields.io/badge/Dart-315B89?style=flat-square) ![Firebase](https://img.shields.io/badge/Firebase-315B89?style=flat-square) ![Python](https://img.shields.io/badge/Python-315B89?style=flat-square) ![Gemini](https://img.shields.io/badge/Gemini-315B89?style=flat-square) ![Selenium](https://img.shields.io/badge/Selenium-315B89?style=flat-square) ![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-315B89?style=flat-square)

[Overview](#overview) · [Features](#features) · [Architecture](#architecture) · [Tech Stack](#tech-stack) · [How to Run](#how-to-run)

</div>

---

## Overview

학과 웹사이트의 공지사항과 대학생활 정보를 모바일에서 통합 조회하는 서비스입니다. Python 크롤러가 공지를 수집하고 Gemini 기반 분류기가 공지 유형을 판정하며, Firebase를 통해 모바일 앱에 데이터를 전달합니다. 학과 정보 접근성을 높이고 필요한 공지를 빠르게 찾도록 지원합니다.

## Features

| 기능 | 설명 |
| --- | --- |
| 공지 수집 | Selenium 및 BeautifulSoup 기반 학과 웹사이트 수집 |
| AI 자동 분류 | 학사·장학·취업·외부행사·학과행사·공모전 분류, API 실패 시 키워드 fallback |
| 공지 탐색 | 검색, 카테고리, 중요·긴급·인기 공지 및 스크랩 |
| 대학생활 | 캘린더, 식단, 그룹, 홈 위젯 설정 |
| 알림 | FCM 토큰 관리, 공지 토픽 구독 및 로컬 알림 |
| 지도 | 실내 강의실 검색, 인접 리스트와 BFS 기반 경로 탐색, 3D 지도 화면 |
| 관리 | 사용자 승인, 공지 및 행사 관리 화면 |

## Architecture

~~~mermaid
flowchart LR
  G["GitHub Actions"] --> C["Python Crawler"]
  W["학과 웹사이트"] --> C
  C --> AI["Gemini / Keyword Fallback"]
  AI --> DB["Cloud Firestore"]
  DB --> APP["Flutter App"]
  AUTH["Firebase Auth"] --> APP
  DB --> N["FCM 알림"]
  N --> APP
~~~

| Path | Responsibility |
| --- | --- |
| `app/lib/` | 화면, 모델, Firebase 서비스, 지도 기능 |
| `ai_server/` | 크롤링, AI 분류, 식단 수집 및 데이터 관리 |
| `android/functions/` | Firebase Functions |
| `.github/workflows/` | 예약 수집 및 유지보수 작업 |

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile | Flutter, Dart |
| Backend & Storage | Firebase Authentication, Cloud Firestore, Firebase Storage, Cloud Functions |
| AI & Crawling | Python, Gemini API, Selenium, BeautifulSoup |
| Notification | Firebase Cloud Messaging, Flutter Local Notifications |
| Operations | GitHub Actions, Firebase Crashlytics, Firebase Analytics |

## How to Run

### 1. Prerequisites

Flutter SDK(Dart 3.10 호환), Android 또는 iOS 개발 환경, Firebase 프로젝트 및 Python 3.10/3.11, Chrome이 필요합니다. 자체 개발용 Firebase 설정을 사용하고 기존 운영 데이터에 임의로 연결하지 마세요.

### 2. Mobile App

~~~bash
git clone https://github.com/Hyunhoim/MY_CSE.git
cd MY_CSE/app
flutter pub get
flutter run
~~~

Firebase Authentication, Firestore, Storage 및 Messaging 설정을 실행 환경에 맞게 준비합니다. iOS 실행에는 macOS와 Xcode가 필요합니다.

### 3. Crawler & AI Classification

저장소 루트에서 실행합니다.

~~~bash
python -m venv .venv
# 가상환경 활성화 후
python -m pip install -r ai_server/requirements.txt
# FIREBASE_KEY 및 GEMINI_API_KEY 환경변수 설정 후
python ai_server/crawler.py
~~~

`FIREBASE_KEY`는 Firebase 서비스 계정 JSON, `GEMINI_API_KEY`는 Gemini API 인증 정보입니다. 키 값이나 서비스 계정 파일을 Git에 추가하지 않습니다. 크롤러는 Firestore에 쓰기 작업을 수행하므로 테스트 프로젝트를 사용합니다. 예약 실행은 GitHub Actions의 관련 Secrets를 설정한 뒤 사용합니다.

[원본 저장소](https://github.com/kdhun-0814/MY_CSE) · [모바일 프로젝트](app/) · [수집 서버](ai_server/)
