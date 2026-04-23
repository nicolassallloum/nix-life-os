<?php

namespace App\Enums;

enum AccountType: string
{
    case MAIN = 'main';
    case SAVINGS = 'savings';
    case CARD = 'card';
}