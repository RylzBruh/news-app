from flask import Flask, render_template, jsonify
from .news_scraper import get_magnificent_seven_news


app = Flask(__name__)


@app.route('/')
def index():
    news_items = get_magnificent_seven_news()
    return render_template('index.html', news_items=news_items)


@app.route('/health')
def health_check():
    return jsonify({"status": "healthy"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
