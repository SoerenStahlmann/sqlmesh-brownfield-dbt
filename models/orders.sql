{{
    config(
        materialized='incremental',
        post_hook = "{{ dump_as_parquet(this) }}",
        unique_key='order_id'
    )
}}

{% set payment_methods = ['credit_card', 'coupon', 'bank_transfer', 'gift_card'] %}

with orders as (

    select * from {{ ref('stg_orders') }}

    {% if sqlmesh_incremental is defined %}
        where
        order_date BETWEEN '{{ start_ds }}' AND '{{ end_ds }}'
    {% elif is_incremental() %}
        where order_date > (select max(order_date) from {{ this }})
    {% endif %}
),

payments as (

    select * from {{ ref('stg_payments') }}

),

order_payments as (

    select
        order_id,

        {% for payment_method in payment_methods -%}
        sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount,
        {% endfor -%}

        sum(amount) as total_amount

    from payments

    group by order_id

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,

        {% for payment_method in payment_methods -%}

        order_payments.{{ payment_method }}_amount,

        {% endfor -%}

        order_payments.total_amount as amount

    from orders


    left join order_payments
        on orders.order_id = order_payments.order_id

)

select * from final
