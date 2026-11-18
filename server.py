from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware #handle Cross-Origin Resource Sharing request
from pydantic import BaseModel # to define and validate request data
from moderation_test import check_message
# connect flutter frontend and moderation backend
app = FastAPI()

# Allows requests from all origins during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Defines the structure of the incoming message request
class MessageRequest(BaseModel):
    text: str # text must be string

# Registers a POST API endpoint for message moderation
@app.post("/check-message")
def check_message_endpoint(req: MessageRequest): # store data receive from flutter to req
    return check_message(req.text) # Passes the message to the moderation function and returns the result