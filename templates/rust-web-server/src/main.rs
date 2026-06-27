use actix_web::{App, HttpServer, web};

fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(web::resource("/").to(|| async { "Hello Nixers!\n" }));
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| App::new().configure(config))
        .bind("127.0.0.1:8080")?
        .run()
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::dev::Service;
    use actix_web::{App, Error, body::to_bytes, http, test};

    #[actix_rt::test]
    async fn test() -> Result<(), Error> {
        let mut app = test::init_service(App::new().configure(config)).await;

        let resp = app
            .call(test::TestRequest::get().uri("/").to_request())
            .await
            .unwrap();

        assert_eq!(resp.status(), http::StatusCode::OK);

        let body = to_bytes(resp.into_body()).await.unwrap();

        assert_eq!(body.as_ref(), b"Hello Nixers!\n");

        Ok(())
    }
}
