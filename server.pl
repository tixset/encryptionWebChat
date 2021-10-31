#!/usr/bin/env perl
#	Author: Zelenov Anton <tixset@gmail.com>
#	GitHub: https://github.com/tixset/encryptionWebChat
use strict;
use warnings;
use utf8;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;
use POSIX qw(strftime);

my $socketPort = 5555;
my $clientHost = ""; # На каком хосте расположена ваша вебка (необходимо для запрета стронних клиентов, если значение пустое - отключено, пример: https://tixset.github.io)
my $messageMaxLength = 0; # Ограничение по длинне сообщений (если значение = 0 - отключено)
my %connections;
my %groups;
my $cv = AE::cv;

binmode(STDOUT, ':utf8');
printd("Server is started");
sub printd{
	my $ds = strftime "%Y-%m-%d %H:%M:%S", localtime;
	printf($ds . " " . shift . "\n");
}
sub sendInGroup{ # Отправка всем членам группы
	my ($group, $receiveStr, $frame) = (shift, shift, shift);
	my $groupCount = 0;
	foreach my $i (keys %connections) {
		if ($groups{$i} eq $group) {
			$connections{$i}->push_write($frame->new($receiveStr)->to_bytes);
			$groupCount++;
		}
	}
	return $groupCount;
}
sub clientDestroy{ # Отключаем выбранного клиента
	my ($handle, $host) = (shift, shift);
	delete $groups{$handle};
	delete $connections{$handle};
	$handle->destroy;
	printd("Disconnected: ${host}");
}
tcp_server(undef, $socketPort, sub {
	my ($clsock, $host, $socketPort) = @_;
	my $hs = Protocol::WebSocket::Handshake::Server->new;
	my $frame = Protocol::WebSocket::Frame->new;
	printd("Connected: ${host}");
	my $handle = AnyEvent::Handle->new(fh => $clsock);
	$handle->on_read(
	sub {
		my $handle = shift;
		my $chunk = $handle->{rbuf};
		# Запретить сторонним клиентам подключаться к Вашему серверу 
        if (length($clientHost) != 0) {
			my @headersArray = split('\r\n', $chunk);
			foreach my $el (@headersArray) {
				my @line = split(': ', $el);
				if ($line[0] eq "Origin") {
					if ($line[1] ne $clientHost) {
						printd("Someone else's client: ${host} -> ${line[1]} -> my_server");
						clientDestroy($handle, $host);
					}
					last;
				}
			}
		}
		$handle->{rbuf} = undef;
		if (!$hs->is_done) {
			$hs->parse($chunk);
			if ($hs->is_done) {
				$handle->push_write($hs->to_string);
				return;
			}
		}
		$frame->append($chunk);
		while (my $receiveStr = $frame->next) { # Получаем текст
			printd("Receive string = $receiveStr");
			if (index($receiveStr, ':') != -1) {
				my @receiveArr = split(':', $receiveStr);
				$groups{$handle} = $receiveArr[0];
				# Ограничение по длинне сообщений
				if($messageMaxLength > 0) {
					$receiveStr = substr($receiveStr,0 , $messageMaxLength);
				}
				my $groupCount = sendInGroup($receiveArr[0], $receiveStr, $frame); # Отправляем текст всем в группе
				if (($receiveArr[1] eq "enterRheRoom") or ($receiveArr[1] eq "getUserCount")) {
					$handle->push_write($frame->new("userCount:${groupCount}")->to_bytes); # Сообщаем клиенту количество пользователей в комнате
				}

			}
		}
	});
	$handle->on_eof( # Если пользователь закрыл страницу чата
	sub {
		my ($hd) = @_;
		# Говорим клиентам что надо бы переспросить количество пользователей в комнате
		# Cервер не знает кто конкретно отключился т.к. не хранит имена, но знает что количество пользователей в комнате уменьшилось на одного
		sendInGroup($groups{$hd}, "reAskUserCount:", $frame); 
		clientDestroy($hd, $host); # Уничтожаем его хэши
	});
	# Создаем хэши для нового пользователя
	$connections{$handle} = $handle;
	$groups{$handle} = "";
	return;
});
$cv->recv;
