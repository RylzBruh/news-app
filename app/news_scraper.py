import os
from newsapi import NewsApiClient
from datetime import datetime, timedelta


def get_magnificent_seven_news():
    # Get API key from environment variable
    api_key = os.getenv('NEWS_API_KEY')
    newsapi = NewsApiClient(api_key=api_key)

    # Define the Magnificent Seven companies
    companies = [
        'Apple',
        'Microsoft',
        'Alphabet',
        'Amazon',
        'NVIDIA',
        'Meta',
        'Tesla'
    ]
    all_news = []

   # Get news for each company
    for company in companies:
        try:
            news = newsapi.get_everything(
                q=f'{company} stock',
                language='en',
                from_param=(datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d'),
                to=datetime.now().strftime('%Y-%m-%d'),
                sort_by='publishedAt'
            )          
           # Add company name to each article
            for article in news['articles']:
                article['company'] = company
                all_news.append(article)              
        except Exception as e:
            print(f"Error fetching news for {company}: {str(e)}")
    # Sort all news by date
    all_news.sort(key=lambda x: x['publishedAt'], reverse=True)
    return all_news[:50]  # Return top 50 news items