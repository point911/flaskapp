from flask import Flask, render_template, json
from flask.ext.mysql import MySQL

mysql = MySQL()
app = Flask(__name__)
app.config.from_pyfile('database.cfg')

mysql.init_app(app)


@app.route('/')
def main():
    version = showVersion()
    return render_template('index.html', version=version)


def showVersion():
    myfile = '/tmp/app-version.txt'
    try:
        with open(myfile) as f:
            message = '{0}'.format(f.read())
    except IOError:
        message = '\n\nFile not found: ' + myfile
    return message


@app.route('/showEntries')
def showEntries():
    connection = None
    cursor = None
    version = showVersion()

    try:
        connection = mysql.connect()

        cursor = connection.cursor()
        cursor.execute('''SELECT * FROM files''')
        result = cursor.fetchall()

        files = []
        for entry in result:
            record = {
                    'id': entry[0],
                    'name': entry[1],
            }
            files.append(record)

        return render_template('db.html', version=version, students=files)
    except Exception as e:
        return json.dumps({'error':str(e)})
    finally:
        if connection:
            connection.close()
        if cursor:
            cursor.close()


if __name__ == "__main__":
    app.run(host='0.0.0.0',debug=True, port=8080)
