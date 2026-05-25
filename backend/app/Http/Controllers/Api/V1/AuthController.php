$user = User::where('email', $request->email)->first();

if (!$user || !Hash::check($request->password, $user->password)) {
    return response()->json([
        'success' => false,
        'message' => 'Invalid login credentials.',
    ], 401);
}
