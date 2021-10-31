# Шифрованный Анонимный Веб-Чат

Для демонстрации работы шифрования Виженера и протокола обмена ключами Диффи-Хеллмана решил написать простенький веб-чатик с сервером на сокете.

* *Подробнее про шифрование Виженера: https://github.com/tixset/VigenereCipher*
* *Подробнее про протокола Диффи-Хеллмана: https://github.com/tixset/DiffieHellmanProtocol*

Чат решено было сделать как можно более анонимным, для этого я отказался от бэкенда и решил в качестве сервера использовать сокет.

Имя пользователя для чата генерится рандомно, его можно сменить в дальнейшем на такое-же рандомное, для авторизации в чате достаточно только имени и названия комнаты.

Серверный скрипт не записывает ни куда ни какие данные, данные в нем хранятся непосредственно в переменных.

При этом в переменных хранятся только хэши коннектов и список комнат.

В чате шифруются, с помощью шифрования Виженера только сообщения, системные команды, например команда перехода в комнату - не шифруются.

По умолчанию при входе в чат установлена комната "MAIN" и ключ шифрования "default", эти данные Вы можете сменить воспользовавшись соответствующими формами ввода.

При смене комнаты всем пользователям комнаты которую Вы покидаете приходит сообщение о том что Вы покинули комнату, а в комнату в которую Вы входите, соответственно, приходит сообщение о входе. А вот если Вы например закроете страницу чата, то все остальные пользователи в этой комнате получат сообщение от сервера что количество пользователей в группе изменилось. Сервер не знает кто конкретно отключился т.к. не хранит имена, но знает, что количество пользователей в комнате уменьшилось на одного.

<img alt="tixset, encryptionWebChat, mobile" align="right" width="300" src="https://github.com/tixset/encryptionWebChat/raw/main/screenshots/mobile.jpg">

При смене ключа шифрования Вы получаете вопрос от интерфейса "Предложить этот ключ членам группы?" если Вы откажетесь, то ключ сменится только у Вас, а если согласитесь то между всеми членами группы, у которых на данный момент установлен тот же ключ шифрования что и у Вас, произойдет обмен ключами по протоколу Диффи-Хеллмана.
При этом все они получат Ваш ключ, но принимать его или нет, остается на их усмотрение.
Выглядит это как системное сообщение с кнопкой "Принять" в котором говорится что пользователь с таким-то именем предлагает Вам свой ключ шифрования.
Причем если несколько пользователей предложат свой ключ шифрования, то пользователи могут принять любой из них и даже свободно переключаться между ними.

Пользователи с разным шифрованием получают друг от друга нечитаемый текст.

При разрыве соединения с сервером чат попытается переподключиться, на это дается 10 попыток, с интервалом 3 секунды.

Интерфейс чата тестил в браузере google chrome, чат так же корректно работает и на мобильных устройствах.

Серверная часть чата имеет некоторого рода "защиту" от сторонних клиентов.
Если в переменную "$clientHost" поместить имя вашего хоста на котором находится вебка чата, например "https://tixset.github.io" то обращения от всех остальных хостов будут дропаться.

Так же в серверном скрипте есть возможность ограничить количество передаваемого в сообщениях текста, для этого укажите Ваше значение в переменной "$messageMaxLength". Рекомендую например 2000.
Не указывайте слишком маленькое значение, иначе даже системные сообщения будут обрезаться и следовательно чат не будет работать.

## Установка
``` bash
apt install -y git perl cpanminus make gcc apache2
cpanm AnyEvent::WebSocket::Server
cd /home/`whoami`/
git clone https://github.com/tixset/encryptionWebChat
cd encryptionWebChat
chmod +x start_server.sh
cp -a www/* /var/www/html/
```

Если веб-интерфейс Вашего чата и серверный скрипт расположены не на одной и той же машине, то не забудьте в js-скрипте "js/script.js" поменять значение переменной "soketHost" на ip-адрес вашего сервера.

## Запуск сервера
Запустить серверную часть чата очень просто.
``` bash
perl server.pl
```
В определенных ситуациях сервер может вылететь с ошибкой, для этого я создал скрипт "start_server.sh" который его запустит/перезапустит.
``` bash
/home/`whoami`/encryptionWebChat/start_server.sh
```
Если Вы не хотите скрыть вывод текстовой информации на сервере то можете просто дописать " > /dev/null 2>&1 &" в конец строки:
``` bash
/home/`whoami`/encryptionWebChat/start_server.sh > /dev/null 2>&1 &
```
Для добавления серверного скрипта в автозагрузку можете прописать вышеприведенную команду запуска, например, в скрипт "/etc/rc.local" перед строкой "exit 0".

Не забудьте дописать в конце строки запуска амперсанд "&" через пробел, если его там нет.

Для разгрузки сервера рекомендую написать скриптик который периодически будет убивать процесс perl, тем самым мы разорвем висящие коннекты и перезапустим серверный сокет.
При этом все подключенные на данный момент пользователи автоматически переподключатся.

---

# Encrypted Anonymous Web-Chat

To demonstrate the work of the Vigenere Cipher and the Diffie-Hellman key exchange protocol, I decided to write a simple web chat with a server on a socket.

* *Learn more about Vigenere Cipher: https://github.com/tixset/VigenereCipher*
* *Learn more about the Diffie-Hellman protocol: https://github.com/tixset/DiffieHellmanProtocol*

It was decided to make the chat as anonymous as possible, for this I abandoned the backend and decided to use a socket as a server.

The username for the chat is generated randomly, it can be changed in the future to the same random one, only the name and the name of the room are enough for authorization in the chat.

The server script does not write any data anywhere, the data in it is stored directly in variables.

At the same time, only hashes of connections and a list of rooms are stored in variables.

In the chat, only messages, system commands, for example, the command to go to the room, are encrypted, with the help of the Vision encryption, are not encrypted.

By default, when entering the chat, the "MAIN" room and the "default" encryption key are installed, you can change these data using the appropriate input forms.

When changing rooms, all users of the room you are leaving receive a message that you have left the room, and the room you are entering, respectively, receives an entry message. But if, for example, you close the chat page, then all other users in this room will receive a message from the server that the number of users in the group has changed. The server does not know who specifically disconnected because it does not store names, but it knows that the number of users in the room has decreased by one.

<img alt="tixset, encryptionWebChat, mobile" align="right" width="300" src="https://github.com/tixset/encryptionWebChat/raw/main/screenshots/mobile.jpg">

When you change the encryption key, you get a question from the interface "Offer this key to the group members?" if you refuse, then the key will be changed only by you, and if you agree, then all members of the group who currently have the same encryption key installed as you will exchange keys using the Diffie-Hellman protocol.
At the same time, they will all receive your key, but whether to accept it or not remains at their discretion.
It looks like a system message with a "Accept" button that says that a user with such and such a name offers you his encryption key.
Moreover, if several users offer their encryption key, then users can accept any of them and even switch freely between them.

Users with different encryption receive unreadable text from each other.

When the connection with the server is disconnected, the chat will try to reconnect, this is given 10 attempts, with an interval of 3 seconds.

The chat interface was tested in the Google chrome browser, the chat also works correctly on mobile devices.

The server part of the chat has some kind of "protection" from third-party clients.
If you put the name of your host on which the webcam chat is located in the variable "$Clienthost", for example "https://tixset.github.io " then the requests from all other hosts will be dropped.

Also, in the server script, it is possible to limit the amount of text transmitted in messages, to do this, specify your value in the variable "$messagemaxlength". I recommend for example 2000.
Do not specify too small a value, otherwise even system messages will be cut off and therefore the chat will not work.

## Installation
``` bash
apt install -y git perl cpanminus make gcc apache2
cpanm AnyEvent::WebSocket::Server
cd /home/`whoami`/
git clone https://github.com/tixset/encryptionWebChat
cd encryptionWebChat
chmod +x start_server.sh
cp -a www/* /var/www/html/
```

If the web interface of your chat and the server script are not located on the same machine, then do not forget in the js-script "js/script.js" change the value of the variable "Sokethost" to the ip address of your server.

## Starting the server
It is very easy to start the server part of the chat.
``` bash
perl server.pl
```
In certain situations, the server may crash with an error, for this I created a script "start_server.sh " which will start/restart it.
``` bash
/home/`whoami`/encryptionWebChat/start_server.sh
```
If you don't want to hide the output of text information on the server, you can simply add " > /dev/null 2>&1 &" to the end of the line:
``` bash
/home/`whoami`/encryptionWebChat/start_server.sh > /dev/null 2>&1 &
```
To add a server script to the startup, you can write the above startup command, for example, in the script "/etc/rc.local" before the line "exit 0".

Don't forget to add the ampersand "&" separated by a space at the end of the launch line, if it's not there.

To unload the server, I recommend writing a script that will periodically kill the perl process, thereby we will break the hanging connections and restart the server socket.
At the same time, all currently connected users will automatically reconnect.
