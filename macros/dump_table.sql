{% macro dump_as_parquet(this) %}
    {% if execute %}
        COPY {{this}} TO 'output_dump_{{this.table}}.csv' (FORMAT csv);
    {% endif %}
{% endmacro %}