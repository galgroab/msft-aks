from flask import Flask, json

info = [{"company": "Microsoft", "name": "Gal Grossman"}]

api = Flask(__name__)

@api.route('/', methods=['GET'])
def get_info():
  return json.dumps(info)

if __name__ == '__main__':
    api.run(host="0.0.0.0") 