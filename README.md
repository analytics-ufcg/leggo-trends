# Leg.go Trends

Módulo que usa informações adquiridas de redes sociais e buscadores sobre proposições para ver o engajamento da população.

## Docker

Criamos um Docker para que o usuário consiga rodar os scripts independente do ambiente.

Para rodá-lo:

Caso seja a primeira vez:

```
docker-compose run trends
```

Caso faça alterações nos scripts:

```
docker-compose build
```

E, novamente:

```
docker-compose run trends
```
