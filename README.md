# RAG Medical Chatbot

A Retrieval-Augmented Generation (RAG) based medical chatbot that answers medical questions using a knowledge base built from medical documents. The chatbot uses LangChain, FAISS vector store, and Groq's LLaMA model to provide accurate, context-aware medical information.

## 🔍 Features

- **RAG-based Q&A**: Answers medical questions using retrieved context from medical documents
- **PDF Document Processing**: Loads and processes PDF medical documents
- **Vector Search**: Uses FAISS for efficient similarity search
- **Modern LLM Integration**: Powered by Groq's LLaMA 3.1 model via LangChain
- **Web Interface**: Simple Flask-based web UI for interactive conversations
- **Session Management**: Maintains conversation history during the session
- **Custom Prompts**: Tailored prompts for concise medical answers (2-3 lines)

## 🛠️ Tech Stack

- **Python 3.10+**
- **LangChain 1.x**: For RAG pipeline and chain orchestration
- **LangChain Community**: For document loaders and vector stores
- **LangChain Groq**: For LLM integration
- **LangChain HuggingFace**: For embeddings
- **FAISS**: Vector database for similarity search
- **Flask**: Web framework
- **Sentence Transformers**: Embedding model (all-MiniLM-L6-v2)
- **PyPDF**: PDF document processing

## 📋 Prerequisites

- Python 3.10 or higher
- pip or conda
- Groq API key ([Get one here](https://console.groq.com/))
- HuggingFace token (optional, for private models)

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd RAG-MEDICAL-CHATBOT
```

### 2. Create Virtual Environment

Using venv:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Or using conda:
```bash
conda create -n rag-medical python=3.10
conda activate rag-medical
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
GROQ_API_KEY=your_groq_api_key_here
HF_TOKEN=your_huggingface_token_here  # Optional
```

## ⚙️ Configuration

Configuration settings are defined in `app/config/config.py`:

- `HUGGINGFACE_REPO_ID`: Embedding model repository (default: "mistralai/Mistral-7B-Instruct-v0.3")
- `DB_FAISS_PATH`: Path to FAISS vector store (default: "vectorstore/db_faiss")
- `DATA_PATH`: Path to medical documents (default: "data/")
- `CHUNK_SIZE`: Text chunk size for splitting documents (default: 500)
- `CHUNK_OVERLAP`: Overlap between chunks (default: 50)

## 📚 Usage

### Step 1: Prepare Medical Documents

Place your PDF medical documents in the `data/` directory:

```bash
mkdir -p data
# Copy your PDF files to data/
```

### Step 2: Build Vector Store

Process PDFs and create the vector store:

```bash
python -m app.components.data_loader
```

This will:
- Load all PDF files from the `data/` directory
- Split them into chunks
- Generate embeddings
- Store them in FAISS vector database

### Step 3: Run the Application

Start the Flask application:

```bash
python app/application.py
```

The application will start on `http://0.0.0.0:5000` (accessible at `http://localhost:5000`).

### Step 4: Use the Chatbot

1. Open your browser and navigate to `http://localhost:5000`
2. Type your medical question in the text area
3. Click "Send" to get an answer
4. Use "Clear Chat" to reset the conversation

## 📁 Project Structure

```
RAG-MEDICAL-CHATBOT/
├── app/
│   ├── __init__.py
│   ├── application.py          # Flask application entry point
│   ├── components/
│   │   ├── data_loader.py      # PDF processing and vector store creation
│   │   ├── embeddings.py       # Embedding model initialization
│   │   ├── llm.py              # LLM (Groq) initialization
│   │   ├── pdf_loader.py       # PDF loading and text splitting
│   │   ├── retriever.py        # RAG chain creation
│   │   └── vector_store.py     # FAISS vector store operations
│   ├── config/
│   │   └── config.py           # Configuration settings
│   ├── common/
│   │   ├── custom_exception.py # Custom exception classes
│   │   └── logger.py           # Logging configuration
│   └── templates/
│       └── index.html          # Web UI template
├── data/                       # Medical PDF documents
├── vectorstore/                # Generated FAISS vector store
│   └── db_faiss/
├── logs/                       # Application logs
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Docker configuration
└── README.md                   # This file
```

## 🔌 API Endpoints

### GET `/`
- Renders the chat interface
- Displays conversation history from session

### POST `/`
- Accepts user question via form data (`prompt`)
- Returns answer based on retrieved context
- Updates session with user question and assistant response

### GET `/clear`
- Clears the conversation history from session
- Redirects to home page

## 🐳 Docker Deployment

### Build Docker Image

```bash
docker build -t rag-medical-chatbot .
```

### Run Docker Container

```bash
docker run -p 5000:5000 \
  -e GROQ_API_KEY=your_groq_api_key \
  -e HF_TOKEN=your_hf_token \
  rag-medical-chatbot
```

Or using docker-compose (create `docker-compose.yml`):

```yaml
version: '3.8'
services:
  chatbot:
    build: .
    ports:
      - "5000:5000"
    environment:
      - GROQ_API_KEY=${GROQ_API_KEY}
      - HF_TOKEN=${HF_TOKEN}
    volumes:
      - ./vectorstore:/app/vectorstore
      - ./data:/app/data
```

## 🔧 How It Works

1. **Document Processing**: PDFs are loaded and split into chunks
2. **Embedding Generation**: Text chunks are converted to vectors using sentence transformers
3. **Vector Storage**: Embeddings are stored in FAISS for fast similarity search
4. **Query Processing**: User questions are embedded and used to retrieve relevant chunks
5. **Answer Generation**: Retrieved context and question are passed to LLM for answer generation
6. **Response Formatting**: LLM generates a concise 2-3 line answer based on the context

## 📝 Logging

Logs are stored in the `logs/` directory with daily rotation. Log files are named `log_YYYY-MM-DD.log`.

## ⚠️ Important Notes

- **Medical Disclaimer**: This chatbot is for informational purposes only and should not replace professional medical advice
- **Vector Store**: Ensure the vector store is built before running the application
- **API Keys**: Keep your API keys secure and never commit them to version control
- **Model Selection**: The default model is `llama-3.1-8b-instant`. You can modify it in `app/components/llm.py`

## 🐛 Troubleshooting

### Import Errors
If you encounter `ModuleNotFoundError`, ensure:
- Virtual environment is activated
- All dependencies are installed: `pip install -r requirements.txt`
- Python version is 3.10 or higher

### Vector Store Not Found
Run the data loader to create the vector store:
```bash
python -m app.components.data_loader
```

### API Key Errors
Verify your `.env` file contains valid API keys:
```bash
GROQ_API_KEY=your_actual_key_here
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is part of the Andela GenAI program.

## 🙏 Acknowledgments

- LangChain for the RAG framework
- Groq for fast LLM inference
- HuggingFace for embedding models
- FAISS for efficient vector search



