import pytest
import os
from dotenv import load_dotenv
import app.news_scraper as news_scraper

# Load environment variables
load_dotenv()

def test_news_fetching_with_env_api_key():
    """Test if get_magnificent_seven_news works with API key from .env"""
    
    assert os.getenv("NEWS_API_KEY"), "NEWS_API_KEY not found in .env file"

    news = news_scraper.get_magnificent_seven_news()

    assert isinstance(news, list)
    assert len(news) > 0
