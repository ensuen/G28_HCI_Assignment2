# G28 HCI Assignment 2 - WANG Chat & AI Moderation System

A cross-platform Flutter chat application backed by Firebase Cloud Firestore and a Python FastAPI moderation server using the OpenAI Moderation API.

## Prerequisites
- **Flutter SDK** (with Google Chrome installed for web execution)
- **Python 3.9+**

## How to Run

### 1. Start the Backend Server (FastAPI + AI Moderation)
Click the green **`<> Code`** button on this GitHub repository page and select **Download ZIP**. Furthermore, **Unzip (extract)** the downloaded file.
Open a regular Terminal, navigate into the downloaded project folder (e.g., type `cd ` and drag the folder into the terminal), and run:

    # Create and activate virtual environment
    python3 -m venv venv
    source venv/bin/activate        # On Windows, use: venv\Scripts\activate

    # Install dependencies
    python -m pip install -r requirements.txt

Generate the `.env` file automatically by running this single command in the terminal (replace the placeholder with the shared API key stated in the G28 HCI Assignment 2 Report):

    # On macOS / Linux:
    echo 'OPENAI_API_KEY="paste-the-shared-api-key-here"' > .env

    # On Windows (Command Prompt / PowerShell):
    echo OPENAI_API_KEY="paste-the-shared-api-key-here" > .env

Start the backend server (keep this terminal running):

    python -m uvicorn server:app --reload

*Verification: You should see `Application startup complete.` and `Uvicorn running on http://127.0.0.1:8000` in the terminal.*

---

### 2. Start the Frontend App (Flutter)
Open a **second** terminal, **navigate into the same downloaded project folder again** (type `cd ` and drag the folder into this new terminal), and run:

    flutter pub get
    flutter run -d chrome

*Verification: Google Chrome will automatically launch the application and connect to Firebase Firestore.*

---

## How to Test (Demo Scenarios)
1. **Enable Audio**: Turn on the volume of your device to hear the send/alert sound effects.
2. **Normal Message (Allowed)**: Send a standard greeting or collateral-related inquiry, such as `"Hello"` or `"Is the item still under warranty?"`. This message will pass moderation and appear in the chat.
3. **Personal Information (Blocked)**: Send a message containing contact details, such as a phone number (`"012-3456789"`) or email address. Since sharing personal information is prohibited, the message will be blocked with an alert.
4. **Loan & Negotiation Topics (Blocked)**: Send a message containing restricted financial keywords such as `"discount"`, `"loan"`, or `"repay"`. Off-platform negotiation and loan discussions are restricted and will be blocked.
5. **Harmful Content (Blocked by OpenAI Moderation API)**: Send a message containing aggressive or harmful language (e.g., `"Kill"` or insults). It will be flagged by the OpenAI Moderation API and blocked.