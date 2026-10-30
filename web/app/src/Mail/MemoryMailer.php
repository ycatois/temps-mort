<?php
declare(strict_types=1);

namespace TempsMort\Mail;

/** Garde les e-mails en mémoire, pour les tests. */
final class MemoryMailer implements Mailer
{
    /** @var list<array{to:string,subject:string,body:string}> */
    public array $sent = [];

    public function send(string $to, string $subject, string $body): void
    {
        $this->sent[] = ['to' => $to, 'subject' => $subject, 'body' => $body];
    }
}
