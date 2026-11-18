import re
import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

# filter
# ---------- externla API：OpenAI Moderation ----------
def check_moderation(text: str) -> dict:
    response = client.moderations.create(
        model="omni-moderation-latest",
        input=text,
    ) # Sends the input text to the OpenAI Moderation API

    result = response.results[0] # Retrieves the first moderation result from the API response
    if result.flagged:
        flagged_categories = [
            name for name, value in result.categories.model_dump().items() if value
        ]
        return {"allowed": False, "reason": "harmful_content", "detail": flagged_categories}
    return {"allowed": True}


# ---------- Personal Information Filtering ----------
PII_PATTERNS = {
    "phone": r"(\+?6?0?1\d[-\s]?\d{3,4}[-\s]?\d{4})",
    "email": r"[\w.+-]+@[\w-]+\.[\w.]+",
    "mykad": r"\b\d{6}-?\d{2}-?\d{4}\b",
    "bank_account": r"\b\d{10,16}\b",
}

PII_KEYWORDS = [
    "whatsapp", "telegram", "wechat", "instagram", "facebook",
    "my number", "my phone", "address", "email", "phone number"
    "bank account", "ic number",
]

def check_personal_info(text: str) -> dict:
    lowered = text.lower()

    for name, pattern in PII_PATTERNS.items():
        if re.search(pattern, text):
            return {"allowed": False, "reason": "personal_info", "detail": name}

    for keyword in PII_KEYWORDS:
        if keyword in lowered:
            return {"allowed": False, "reason": "personal_info", "detail": keyword}

    return {"allowed": True}


# ---------- Loan Information Filtering ----------
LOAN_KEYWORDS = [
    "interest", "loan", "repay", "repayment", "installment",
    "lower the price", "discount", "negotiate", "transfer money",
    "deposit", "private deal", "outside the app",
]

def check_loan_topic(text: str) -> dict:
    lowered = text.lower()
    for keyword in LOAN_KEYWORDS:
        if keyword in lowered:
            return {"allowed": False, "reason": "loan", "detail": keyword}
    return {"allowed": True}

# without LLM
# ---------- Combine internal n external check ----------
def check_message(text: str) -> dict:
    # 1. Internal checks (fast, free, offline)
    for checker in (check_personal_info, check_loan_topic):
        result = checker(text)
        if not result["allowed"]:
            return result

    # 2. External AI check (OpenAI Moderation API)
    return check_moderation(text)