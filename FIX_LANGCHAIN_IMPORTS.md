# Fix for LangChain Import Error

## Problem
```
ModuleNotFoundError: No module named 'langchain.chains'
```

This error occurs because LangChain v0.1+ has restructured its API. The old `langchain.chains.RetrievalQA` no longer exists.

## Solution

### Option 1: Use LangChain v0.0.x (Quick Fix)

If you want to keep using the old API, downgrade LangChain:

```bash
pip install langchain==0.0.350
```

### Option 2: Update to Modern LangChain API (Recommended)

Update your code to use the new LangChain Expression Language (LCEL) pattern.

#### Old Code (doesn't work):
```python
from langchain.chains import RetrievalQA
from langchain.llms import OpenAI

qa_chain = RetrievalQA.from_chain_type(
    llm=OpenAI(),
    chain_type="stuff",
    retriever=retriever
)
```

#### New Code (LangChain v0.1+):
```python
from langchain.chains import RetrievalQAChain
from langchain_openai import ChatOpenAI
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains import create_retrieval_chain
from langchain_core.prompts import ChatPromptTemplate

# Using LCEL (LangChain Expression Language)
llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)

# Create prompt template
prompt = ChatPromptTemplate.from_template("""
Answer the following question based only on the provided context:

Context: {context}

Question: {input}
""")

# Create document chain
document_chain = create_stuff_documents_chain(llm, prompt)

# Create retrieval chain
qa_chain = create_retrieval_chain(retriever, document_chain)
```

#### Alternative: Using RetrievalQAChain (if available):
```python
from langchain.chains.retrieval_qa import RetrievalQAChain
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)

qa_chain = RetrievalQAChain.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=retriever,
    return_source_documents=True
)
```

## Steps to Fix

1. **Check your LangChain version:**
   ```bash
   pip show langchain
   ```

2. **Update your `app/components/retriever.py`:**
   - Replace old imports with new ones
   - Update the chain creation code

3. **Update requirements.txt:**
   - If using new API: `langchain>=0.1.0`
   - If using old API: `langchain==0.0.350`

## Example Updated retriever.py

```python
from langchain_openai import ChatOpenAI
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains import create_retrieval_chain
from langchain_core.prompts import ChatPromptTemplate

def create_qa_chain(retriever, model_name="gpt-3.5-turbo"):
    """
    Create a QA chain using the modern LangChain API.
    
    Args:
        retriever: The retriever to use for document retrieval
        model_name: The LLM model to use
    
    Returns:
        A retrieval chain ready to answer questions
    """
    # Initialize LLM
    llm = ChatOpenAI(model=model_name, temperature=0)
    
    # Create prompt template
    prompt = ChatPromptTemplate.from_template("""
    Use the following pieces of context to answer the question at the end.
    If you don't know the answer, just say that you don't know, don't try to make up an answer.
    
    Context: {context}
    
    Question: {input}
    
    Answer:
    """)
    
    # Create document chain
    document_chain = create_stuff_documents_chain(llm, prompt)
    
    # Create retrieval chain
    qa_chain = create_retrieval_chain(retriever, document_chain)
    
    return qa_chain
```

## Usage

```python
# Invoke the chain
result = qa_chain.invoke({"input": "What is the treatment for diabetes?"})
answer = result["answer"]
```

