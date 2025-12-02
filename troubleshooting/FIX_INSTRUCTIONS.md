# Fix Instructions for NumPy and LangChain Issues

## Problem Summary
1. **NumPy 2.3.5 incompatibility** - PyTorch/transformers compiled with NumPy 1.x
2. **LangChain import error** - `langchain.chains.retrieval_qa.base` doesn't exist

## Quick Fix Steps

### Step 1: Fix NumPy Version
```bash
cd "RAG-MEDICAL-CHATBOT"
source venv/bin/activate  # if not already activated
pip install "numpy<2.0" --upgrade
```

### Step 2: Check LangChain Version
```bash
python -c "import langchain; print(langchain.__version__)"
```

### Step 3: Fix LangChain Imports

Based on your error, you're using a modern LangChain version. The `RetrievalQA` class has been replaced. Here are the options:

#### Option A: Use RetrievalQAChain (if available)
Update `app/components/retriever.py`:

**Replace:**
```python
from langchain.chains.retrieval_qa.base import RetrievalQA
```

**With:**
```python
from langchain.chains import RetrievalQAChain
```

Then update your `create_qa_chain` function to use `RetrievalQAChain` instead of `RetrievalQA`.

#### Option B: Use Modern LCEL Approach (Recommended for LangChain 0.2.0+)

Replace the old `RetrievalQA` approach with the new LangChain Expression Language (LCEL):

```python
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate

def create_qa_chain(llm, retriever):
    # Create prompt template
    prompt = ChatPromptTemplate.from_template("""
    Use the following pieces of context to answer the question at the end.
    If you don't know the answer, just say that you don't know, don't try to make up an answer.
    
    Context: {context}
    
    Question: {question}
    
    Answer:
    """)
    
    # Create document chain
    document_chain = create_stuff_documents_chain(llm, prompt)
    
    # Create retrieval chain
    retrieval_chain = create_retrieval_chain(retriever, document_chain)
    
    return retrieval_chain
```

#### Option C: Use Legacy LangChain (if you need old API)

If you must use the old `RetrievalQA` API:

```bash
pip uninstall langchain langchain-core langchain-community
pip install langchain==0.0.350
```

Then use:
```python
from langchain.chains import RetrievalQA
```

## Automated Fix

I've created scripts to help:

1. **Fix dependencies:**
   ```bash
   chmod +x fix-dependencies.sh
   ./fix-dependencies.sh
   ```

2. **Fix imports:**
   ```bash
   python fix-retriever.py
   ```

## Manual Fix (If scripts don't work)

1. **Fix NumPy:**
   ```bash
   pip install "numpy<2.0" --upgrade
   ```

2. **Update retriever.py:**
   - Open `app/components/retriever.py`
   - Find the line: `from langchain.chains.retrieval_qa.base import RetrievalQA`
   - Replace with one of the options above based on your LangChain version

3. **Update create_qa_chain function:**
   - If using LCEL (Option B), replace the entire function with the new implementation
   - If using RetrievalQAChain (Option A), change `RetrievalQA` to `RetrievalQAChain` in your code

## Verify Fix

After making changes:
```bash
python app/application.py
```

If you still get errors, share the full traceback and I'll help further!


