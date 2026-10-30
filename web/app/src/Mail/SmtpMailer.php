<?php
declare(strict_types=1);

namespace TempsMort\Mail;

/**
 * Client SMTP minimal, sans authentification ni chiffrement : réservé à Mailpit en local
 * (docker compose, http://localhost:8025). La production utilise PhpMailer.
 */
final class SmtpMailer implements Mailer
{
    public function __construct(private readonly string $host, private readonly int $port, private readonly string $from) {}

    public function send(string $to, string $subject, string $body): void
    {
        $socket = @fsockopen($this->host, $this->port, $errno, $error, 5);
        if ($socket === false) { throw new \RuntimeException("SMTP $this->host:$this->port injoignable : $error"); }
        try {
            $this->expect($socket, 220);
            $this->command($socket, 'EHLO tempsmort.local', 250);
            $this->command($socket, 'MAIL FROM:<' . $this->address($this->from) . '>', 250);
            $this->command($socket, 'RCPT TO:<' . $to . '>', 250);
            $this->command($socket, 'DATA', 354);
            $message = implode("\r\n", [
                'From: ' . $this->from,
                'To: ' . $to,
                'Subject: ' . mb_encode_mimeheader($subject, 'UTF-8'),
                'MIME-Version: 1.0',
                'Content-Type: text/plain; charset=UTF-8',
                'Content-Transfer-Encoding: 8bit',
                '',
                // Une ligne qui commence par un point doit être doublée (RFC 5321, 4.5.2).
                preg_replace('/^\./m', '..', str_replace("\n", "\r\n", str_replace("\r\n", "\n", $body))),
            ]);
            $this->command($socket, $message . "\r\n.", 250);
            $this->command($socket, 'QUIT', 221);
        } finally {
            fclose($socket);
        }
    }

    /** @param resource $socket */
    private function command($socket, string $line, int $code): void
    {
        fwrite($socket, $line . "\r\n");
        $this->expect($socket, $code);
    }

    /** @param resource $socket */
    private function expect($socket, int $code): void
    {
        // Réponses sur plusieurs lignes : « 250-… » jusqu'à « 250 … ».
        do {
            $line = fgets($socket, 512);
            if ($line === false) { throw new \RuntimeException('SMTP : connexion fermée'); }
        } while (isset($line[3]) && $line[3] === '-');
        if ((int) substr($line, 0, 3) !== $code) { throw new \RuntimeException('SMTP : réponse inattendue ' . trim($line)); }
    }

    private function address(string $from): string
    {
        return preg_match('/<([^>]+)>/', $from, $m) ? $m[1] : $from;
    }
}
