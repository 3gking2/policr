import React, { useEffect } from "react";
import { Helmet } from "react-helmet-async";
import { useDispatch } from "react-redux";
import { useLocation } from "react-router-dom";
import { unfixedNav, settingNavIs } from "../actions";

const title = "POLICR · 私有部署";

export default _props => {
  const dispatch = useDispatch();
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  useEffect(() => {
    dispatch(unfixedNav());
    dispatch(settingNavIs("info"));
  }, []);

  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <section className="section hero is-fullheight is-medium is-info">
        <div className="hero-body">
          <div className="container">
            <div className="columns has-text-centered is-centered">
              <p className="subtitle is-3">作者还在撰写内容哦～</p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
