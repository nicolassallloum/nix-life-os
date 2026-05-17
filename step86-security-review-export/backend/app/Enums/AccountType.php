<?php

namespace App\Enums;

enum AccountType: string
{
    case CASH = 'cash';
    case WALLET = 'wallet';
    case BANK = 'bank';
    case CHECKING = 'checking';
    case SAVINGS = 'savings';
    case CURRENT = 'current';
    case CREDIT_CARD = 'credit_card';
    case INVESTMENT = 'investment';
    case OTHER = 'other';
}