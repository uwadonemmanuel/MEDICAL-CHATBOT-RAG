# Fix for LangChain Import Error

## Problem
```
ModuleNotFoundError: No module named 'langchain.chains'
```

## Solution

The `RetrievalQA` class has been moved/replaced in newer versions of LangChain. Here are the fixes:

### Option 1: Use LangChain v0.0.x (Legacy)
If you want to keep using the old API:
```bash
pip install langchain==0.0.350
```

### Option 2: Update to Modern LangChain (Recommended)

In modern LangChain (v0.1.0+), `RetrievalQA` has been replaced. Update your `app/components/retriever.py`:

**Old import:**
```python
from langchain.chains import RetrievalQA
```

**New import (LangChain v0.1.0+):**
```python
from langchain.chains.retrieval_qa.base import RetrievalQA
```

Or better yet, use the newer approach:
```python
from langchain.chains import RetrievalQAChain
# or
from langchain.chains.question_answering import load_qa_chain
```

### Option 3: Use LangChain v0.2.0+ (Latest)

In the latest versions, use:
```python
from langchain.chains.retrieval_qa.base import RetrievalQA
```

Or migrate to the new LCEL (LangChain Expression Language) approach:
```python
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
```

## Quick Fix Steps

1. **Check your LangChain version:**
   ```bash
   pip show langchain
   ```

2. **Update your imports in `app/components/retriever.py`:**
   - If using LangChain < 0.1.0: Keep `from langchain.chains import RetrievalQA`
   - If using LangChain >= 0.1.0: Use `from langchain.chains.retrieval_qa.base import RetrievalQA`
   - If using LangChain >= 0.2.0: Consider migrating to LCEL

3. **Install/update dependencies:**
   ```bash
   pip install langchain langchain-community langchain-core
   ```

## Recommended Modern Approach

For LangChain v0.2.0+, consider using the new LCEL pattern:

```python
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough

def create_qa_chain(llm, retriever):
    # Create prompt
    prompt = ChatPromptTemplate.from_template("""
    Answer the following question based on the context:
    
    Context: {context}
    
    Question: {question}
    
    Answer:
    """)
    
    # Create chain
    document_chain = create_stuff_documents_chain(llm, prompt)
    retrieval_chain = create_retrieval_chain(retriever, document_chain)
    
    return retrieval_chain
```


