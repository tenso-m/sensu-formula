{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu
  - sensu.api_conf # Some handlers need to access the API server
  - sensu.rabbitmq_conf
  - sensu.redis_conf

/etc/sensu/conf.d:
  file.recurse:
    - source: salt://{{ sensu.paths.conf_d }}
    - template: jinja
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

{%- if salt['pillar.get']('sensu:checks') %}

sensu_checks_file:
  file.serialize:
    - name: {{ sensu.paths.checks_file }}
    - dataset:
        checks: {{ salt['pillar.get']('sensu:checks') }}
    - formatter: json
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

{%- endif %}

{%- if salt['pillar.get']('sensu:handlers') %}

sensu_handlers_file:
  file.serialize:
    - name: {{ sensu.paths.handlers_file }}
    - dataset_pillar: sensu:handlers
    - formatter: JSON
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

{% endif %}

/etc/sensu/extensions:
  file.recurse:
    - source: salt://{{ sensu.paths.extensions }}
    - file_mode: 555
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server
   
/etc/sensu/mutators:
  file.recurse:
    - source: salt://{{ sensu.paths.mutators }}
    - file_mode: 555
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-server

/etc/sensu/handlers:
  file.recurse:
    - source: salt://{{ sensu.paths.handlers }}
    - file_mode: 555
    - require:
      - pkg: sensu
    - require_in:
      - service: sensu-server
    - watch_in:
      - service: sensu-server

{% set gem_list = salt['pillar.get']('sensu:server:install_gems', []) %}
{% for gem in gem_list %}
install_{{ gem }}:
  gem.installed:
    - name: {{ gem }}
    - gem_bin: /opt/sensu/embedded/bin/gem
    - rdoc: False
    - ri: False
{% endfor %}

sensu-server:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/redis.json
      - file: /etc/sensu/conf.d/rabbitmq.json
