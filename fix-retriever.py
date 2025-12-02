#!/usr/bin/env python3
"""
Fix LangChain imports in retriever.py based on installed version
"""

import os
import re
import sys

def get_langchain_version():
    """Get LangChain version"""
    try:
        import langchain
        return langchain.__version__
    except ImportError:
        return None

def fix_retriever_file(file_path='app/components/retriever.py'):
    """Fix imports in retriever.py"""
    
    if not os.path.exists(file_path):
        print(f"❌ Error: {file_path} not found")
        return False
    
    # Read current file
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    version = get_langchain_version()
    
    print(f"📝 LangChain version: {version or 'unknown'}")
    print(f"📝 Fixing {file_path}...")
    
    # Pattern 1: Old import - from langchain.chains import RetrievalQA
    old_pattern1 = r'from langchain\.chains import RetrievalQA'
    
    # Pattern 2: Attempted fix - from langchain.chains.retrieval_qa.base import RetrievalQA
    old_pattern2 = r'from langchain\.chains\.retrieval_qa\.base import RetrievalQA'
    
    # Check which pattern exists
    if re.search(old_pattern1, content) or re.search(old_pattern2, content):
        # Try to determine the correct import based on version
        if version:
            major_minor = tuple(map(int, version.split('.')[:2]))
            
            if major_minor >= (0, 2):
                # LangChain 0.2.0+ - Use LCEL or alternative
                print("   Using LangChain 0.2.0+ approach")
                # Replace with LCEL-compatible import
                new_import = """# LangChain 0.2.0+ - Using LCEL approach
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate"""
                
                # Remove old import
                content = re.sub(old_pattern1, '', content)
                content = re.sub(old_pattern2, '', content)
                
                # Add new imports at the top (after existing langchain_core imports if any)
                if 'from langchain_core' in content:
                    # Insert after langchain_core imports
                    content = re.sub(
                        r'(from langchain_core[^\n]+\n)',
                        r'\1' + new_import + '\n',
                        content,
                        count=1
                    )
                else:
                    # Add at the beginning
                    content = new_import + '\n' + content
                    
            elif major_minor >= (0, 1):
                # LangChain 0.1.0 - Try alternative import paths
                print("   Using LangChain 0.1.0+ approach")
                # Try this import path
                new_import = "from langchain.chains import RetrievalQAChain"
                content = re.sub(old_pattern1, new_import, content)
                content = re.sub(old_pattern2, new_import, content)
            else:
                # Legacy - keep old import but ensure it works
                print("   Using legacy LangChain (< 0.1.0)")
                # Keep the original import
                pass
        else:
            # Unknown version - try the most common fix
            print("   Unknown version - trying common fix")
            new_import = "from langchain.chains import RetrievalQAChain"
            content = re.sub(old_pattern1, new_import, content)
            content = re.sub(old_pattern2, new_import, content)
        
        # Only write if content changed
        if content != original_content:
            # Create backup
            backup_path = file_path + '.backup'
            with open(backup_path, 'w') as f:
                f.write(original_content)
            print(f"   ✅ Created backup: {backup_path}")
            
            # Write fixed content
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"   ✅ Fixed imports in {file_path}")
            return True
        else:
            print("   ℹ️  No changes needed")
            return False
    else:
        print("   ℹ️  No old import patterns found")
        return False

if __name__ == '__main__':
    retriever_path = sys.argv[1] if len(sys.argv) > 1 else 'app/components/retriever.py'
    success = fix_retriever_file(retriever_path)
    sys.exit(0 if success else 1)


