// Styles
import "../scss/user.scss";
// Icons
import "@fortawesome/fontawesome-free/js/all";
// Polyfills
import "mdn-polyfills/CustomEvent";
import "mdn-polyfills/String.prototype.startsWith";
import "mdn-polyfills/NodeList.prototype.forEach";
import "mdn-polyfills/Object.assign";
import "mdn-polyfills/Element.prototype.classList";

import React from "react";
import ReactDOM from "react-dom";
import { Provider as ReduxProvider } from "react-redux";
import reduxLogger from "redux-logger";
import thunkMiddleware from "redux-thunk";
import { configureStore } from "redux-starter-kit";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { HelmetProvider } from "react-helmet-async";

// 导入组件和页面
import Header from "./user/components/Header";
import Footer from "./user/components/Footer";
import Index from "./user/pages/Index";
import Advanced from "./user/pages/Advanced";
import QA from "./user/pages/QA";
import GettingStarted from "./user/pages/GettingStarted";

// 创建 Redux store
import Reducers from "./user/reducers";
const DEBUG = process.env.NODE_ENV == "development";
const middlewares = [thunkMiddleware, DEBUG && reduxLogger].filter(Boolean);
const store = configureStore({
  reducer: Reducers,
  middleware: middlewares
});

class App extends React.Component {
  render() {
    return (
      <ReduxProvider store={store}>
        <HelmetProvider>
          <Router>
            <Header />
            <main>
              <Switch>
                <Route path="/advanced">
                  <Advanced />
                </Route>
                <Route path="/qa">
                  <QA />
                </Route>
                <Route path="/getting-started">
                  <GettingStarted />
                </Route>
                <Route path="/">
                  <Index />
                </Route>
              </Switch>
            </main>
            <Footer />
          </Router>
        </HelmetProvider>
      </ReduxProvider>
    );
  }
}

ReactDOM.render(<App />, document.getElementById("app"));
