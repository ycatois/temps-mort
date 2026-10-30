<?php
declare(strict_types=1);

namespace TempsMort\Mail;

/** mail() de PHP : sur o2switch, l'envoi passe par le serveur de messagerie de l'hébergement. */
final class PhpMailer implements Mailer
{
    public function __construct(private readonly string $from) {}

    public function send(string $to, string $subject, string $body): void
    {
        $headers = [
            'From' => $this->from,
            'MIME-Version' => '1.0',
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Content-Transfer-Encoding' => '8bit',
        ];
        if (!mail($to, mb_encode_mimeheader($subject, 'UTF-8'), $body, $headers)) {
            throw new \RuntimeException('Envoi de l\'e-mail impossible');
        }
    }
}
