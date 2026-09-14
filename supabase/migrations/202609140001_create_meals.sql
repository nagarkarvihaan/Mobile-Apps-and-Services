-- Run once in the Supabase SQL Editor for the project's existing Auth users.
-- The transaction creates the table and its access rules together.
begin;

create table public.meals (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    request_id uuid not null,
    name text not null check (char_length(btrim(name)) between 1 and 120),
    calories numeric(7,1) not null check (calories between 0 and 10000),
    protein numeric(6,1) not null check (protein between 0 and 1000),
    carbs numeric(6,1) not null check (carbs between 0 and 1000),
    fat numeric(6,1) not null check (fat between 0 and 1000),
    created_at timestamptz not null default now(),
    unique (user_id, request_id)
);

create index meals_user_date_idx on public.meals (user_id, created_at desc);

alter table public.meals enable row level security;

revoke all on public.meals from public, anon, authenticated;
grant select, insert on public.meals to authenticated;

create policy "Users read their own meals"
    on public.meals for select to authenticated
    using ((select auth.uid()) = user_id);

create policy "Users save their own meals"
    on public.meals for insert to authenticated
    with check ((select auth.uid()) = user_id);

comment on table public.meals is 'Meal nutrition and saved date only; no meal photos.';
comment on column public.meals.request_id is 'Client save request ID, unique per user, to prevent duplicate retries.';
comment on column public.meals.created_at is 'Time the meal was saved; displayed in the device local timezone.';

commit;
