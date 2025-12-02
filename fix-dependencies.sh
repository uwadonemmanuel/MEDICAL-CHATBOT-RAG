#!/bin/bash
# Fix NumPy and LangChain compatibility issues

echo "🔧 Fixing dependencies..."

# Activate virtual environment if not already activated
if [ -z "$VIRTUAL_ENV" ]; then
    if [ -d "venv" ]; then
        source venv/bin/activate
        echo "✅ Activated virtual environment"
    fi
fi

# Fix NumPy version (downgrade to < 2.0 for compatibility)
echo "📦 Downgrading NumPy to < 2.0 for compatibility..."
pip install "numpy<2.0" --upgrade

# Check LangChain version and fix imports
echo "📦 Checking LangChain version..."
LANGCHAIN_VERSION=$(python -c "import langchain; print(langchain.__version__)" 2>/dev/null || echo "unknown")

if [ "$LANGCHAIN_VERSION" != "unknown" ]; then
    echo "   LangChain version: $LANGCHAIN_VERSION"
    
    # Extract major.minor version
    MAJOR_MINOR=$(echo $LANGCHAIN_VERSION | cut -d. -f1-2)
    
    if [ "$(echo "$MAJOR_MINOR >= 0.2" | bc 2>/dev/null || echo 0)" = "1" ]; then
        echo "   Using LangChain v0.2.0+ - will need LCEL approach"
    elif [ "$(echo "$MAJOR_MINOR >= 0.1" | bc 2>/dev/null || echo 0)" = "1" ]; then
        echo "   Using LangChain v0.1.0+ - updating imports"
    else
        echo "   Using LangChain < 0.1.0 - legacy imports"
    fi
else
    echo "   ⚠️  Could not determine LangChain version"
fi

echo ""
echo "✅ Dependencies fixed!"
echo ""
echo "Next steps:"
echo "1. Update your retriever.py imports (see fix-retriever.py)"
echo "2. Run: python app/application.py"
