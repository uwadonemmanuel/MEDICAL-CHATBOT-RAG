#!/usr/bin/env python3
"""
Script to fix LangChain imports in retriever.py
"""

import re
import sys
import os

def fix_retriever_imports(file_path):
    """Fix LangChain imports in retriever.py"""
    
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Try different import patterns based on LangChain version
    # Pattern 1: Old import
    old_pattern = r'from langchain\.chains import RetrievalQA'
    
    # Pattern 2: Check if it's already using a different import
    if re.search(old_pattern, content):
        print("Found old LangChain import. Fixing...")
        
        # Try the modern import path
        new_import = 'from langchain.chains.retrieval_qa.base import RetrievalQA'
        content = re.sub(old_pattern, new_import, content)
        
        # Also check for other common old imports
        content = re.sub(
            r'from langchain\.chains\.question_answering import RetrievalQA',
            new_import,
            content
        )
        
        if content != original_content:
            # Backup original file
            backup_path = file_path + '.backup'
            with open(backup_path, 'w') as f:
                f.write(original_content)
            print(f"Created backup: {backup_path}")
            
            # Write fixed content
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"✅ Fixed imports in {file_path}")
            print(f"   Changed to: {new_import}")
            return True
        else:
            print("No changes needed")
            return False
    else:
        print("No old import pattern found. File might already be updated.")
        return False

if __name__ == '__main__':
    retriever_path = 'app/components/retriever.py'
    
    if len(sys.argv) > 1:
        retriever_path = sys.argv[1]
    
    fix_retriever_imports(retriever_path)


