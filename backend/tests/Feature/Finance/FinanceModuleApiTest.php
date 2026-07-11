<?php

namespace Tests\Feature\Finance;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FinanceModuleApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_account_crud_currency_and_user_isolation(): void
    {
        $create = $this->postJson('/api/v1/finance/accounts', [
            'name' => 'Main Wallet',
            'type' => 'wallet',
            'currency' => 'lbp',
            'opening_balance' => 100000,
            'description' => 'Primary account',
        ]);

        $create->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.account_name', 'Main Wallet')
            ->assertJsonPath('data.currency_code', 'LBP')
            ->assertJsonPath('data.current_balance', 100000);

        $id = $create->json('data.id');

        $this->getJson("/api/v1/finance/accounts/{$id}")
            ->assertOk()
            ->assertJsonPath('data.id', $id);

        $this->patchJson("/api/v1/finance/accounts/{$id}", [
            'name' => 'Updated Wallet',
            'currency' => 'usd',
        ])->assertOk()
            ->assertJsonPath('data.account_name', 'Updated Wallet')
            ->assertJsonPath('data.currency_code', 'USD');

        $other = User::factory()->create();
        Sanctum::actingAs($other);
        $this->getJson("/api/v1/finance/accounts/{$id}")->assertNotFound();
        $this->deleteJson("/api/v1/finance/accounts/{$id}")->assertNotFound();

        Sanctum::actingAs($this->user);
        $this->deleteJson("/api/v1/finance/accounts/{$id}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('finance_accounts', ['id' => $id]);
    }

    public function test_income_expense_transfer_and_dashboard_balances(): void
    {
        $source = $this->postJson('/api/v1/finance/accounts', [
            'name' => 'Cash', 'type' => 'cash', 'currency' => 'USD', 'opening_balance' => 1000,
        ])->assertCreated()->json('data.id');

        $destination = $this->postJson('/api/v1/finance/accounts', [
            'name' => 'Bank', 'type' => 'bank', 'currency' => 'USD', 'opening_balance' => 200,
        ])->assertCreated()->json('data.id');

        $income = $this->postJson('/api/v1/finance/transactions', [
            'account_id' => $source,
            'type' => 'income',
            'amount' => 500,
            'currency' => 'USD',
            'transaction_date' => '2026-07-11',
            'category' => 'Salary',
        ]);
        $income->assertCreated()->assertJsonPath('data.transaction_type', 'income');

        $expense = $this->postJson('/api/v1/finance/transactions', [
            'account_id' => $source,
            'transaction_type' => 'expense',
            'amount' => 125,
            'currency_code' => 'USD',
            'transaction_date' => '2026-07-11',
            'category' => 'Food',
        ]);
        $expense->assertCreated()->assertJsonPath('data.transaction_type', 'expense');

        $transfer = $this->postJson('/api/v1/finance/transactions', [
            'account_id' => $source,
            'transaction_type' => 'transfer',
            'transfer_account_id' => $destination,
            'amount' => 100,
            'currency_code' => 'USD',
            'transaction_date' => '2026-07-11',
        ]);
        $transfer->assertCreated()->assertJsonPath('data.transaction_type', 'transfer');

        $this->getJson('/api/v1/finance/dashboard')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total_income', 500)
            ->assertJsonPath('data.total_expenses', 125)
            ->assertJsonPath('data.total_transfers', 100)
            ->assertJsonPath('data.transaction_count', 3);

        $this->getJson("/api/v1/finance/accounts/{$source}")
            ->assertOk()->assertJsonPath('data.current_balance', 1275);
        $this->getJson("/api/v1/finance/accounts/{$destination}")
            ->assertOk()->assertJsonPath('data.current_balance', 300);

        $expenseId = $expense->json('data.id');
        $this->patchJson("/api/v1/finance/transactions/{$expenseId}", ['amount' => 200])
            ->assertOk()->assertJsonPath('data.amount', 200);
        $this->getJson("/api/v1/finance/accounts/{$source}")
            ->assertJsonPath('data.current_balance', 1200);

        $this->deleteJson("/api/v1/finance/transactions/{$expenseId}")->assertOk();
        $this->getJson("/api/v1/finance/accounts/{$source}")
            ->assertJsonPath('data.current_balance', 1400);
    }

    public function test_category_crud_validation_and_authentication(): void
    {
        $create = $this->postJson('/api/v1/finance/categories', [
            'name' => 'Utilities',
            'type' => 'expense',
            'icon' => 'bolt',
            'color' => '#112233',
        ]);
        $create->assertCreated()
            ->assertJsonPath('data.name', 'Utilities')
            ->assertJsonPath('data.type', 'expense');

        $id = $create->json('data.id');
        $this->patchJson("/api/v1/finance/categories/{$id}", [
            'name' => 'Home Utilities', 'status' => 'inactive',
        ])->assertOk()
            ->assertJsonPath('data.name', 'Home Utilities')
            ->assertJsonPath('data.status', 'inactive');

        $this->postJson('/api/v1/finance/categories', ['name' => '', 'type' => 'invalid'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'type']);

        $this->deleteJson("/api/v1/finance/categories/{$id}")->assertOk();

        auth()->forgetGuards();
        $this->app['auth']->guard()->logout();
        $this->getJson('/api/v1/finance/accounts')->assertUnauthorized();
    }
}
