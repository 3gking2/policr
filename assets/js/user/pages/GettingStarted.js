import React, { useEffect } from "react";
import { Helmet } from "react-helmet-async";
import { useDispatch } from "react-redux";
import { useLocation } from "react-router-dom";
import { unfixedNav, settingNavIs } from "../actions";

const title = "POLICR · 快速入门";
const articleMaiginStyle = {
  marginTop: "1.5rem"
};

export default _props => {
  const dispatch = useDispatch();
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  useEffect(() => {
    dispatch(settingNavIs("primary"));
    dispatch(unfixedNav());
  }, []);

  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>

      <section className="hero is-primary">
        <div className="hero-body">
          <div className="container">
            <h1 className="title is-spaced">快速入门</h1>
            <h2 className="subtitle">通过本页，让机器人工作起来</h2>
          </div>
        </div>
      </section>
      <section id="GettingStartedPage" className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-3">
              <div className="pr-sidebar">
                <aside className="menu">
                  <p className="menu-label">快速入门</p>
                  <ul className="menu-list">
                    <li>
                      <a href="#introduction">项目介绍</a>
                    </li>
                    <li>
                      <a href="#permissions">权限要求</a>
                    </li>
                    <li>
                      <a href="#commands">指令总览</a>
                    </li>
                    <li>
                      <a href="#start">立即开始</a>
                    </li>
                  </ul>
                </aside>
              </div>
            </div>
            <div className="column is9">
              <div className="section">
                <h3 className="title is-3">
                  <a name="introduction" className="anchor"></a>
                  POLICR PROJECT
                </h3>
                <hr />
                <article className="message">
                  <div className="message-body">
                    我厌烦广告，并痛恨四处乱入、广泛加群的垃圾帐号们。
                    <br />
                    我需要一个开放透明的审核制度，定制性强的验证机制。
                  </div>
                </article>
                <div className="content">
                  <ul>
                    <li>用代码证明可行性，用开源保证公信力</li>
                    <li>
                      加入
                      <a href="https://policr.bluerain.io/community">我们</a>
                      ，学习并建设这里
                    </li>
                  </ul>
                </div>
                <div className="field is-grouped is-grouped-multiline">
                  <div className="control">
                    <div className="tags has-addons">
                      <span className="tag is-dark">crystal</span>
                      <span className="tag is-info">0.31.1</span>
                    </div>
                  </div>

                  <div className="control">
                    <div className="tags has-addons">
                      <span className="tag is-dark">policr</span>
                      <span className="tag is-success">
                        0.2.0-dev (d417b06)
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              <div className="section">
                <h3 className="title is-3">
                  <a className="anchor" name="permissions"></a>
                  权限要求
                </h3>
                <hr />
                <article className="message is-danger">
                  <div className="message-body">
                    使用之前需要一些前提，这些前提是保证机器人各功能运作的基础
                  </div>
                </article>
                <div className="content">
                  <ul>
                    <li>访问群消息（未关闭隐私模式）</li>
                    <li>发送群消息（Send messages）</li>
                    <li>删除群消息（Delete messages）</li>
                    <li>封禁群成员（Ban users）</li>
                  </ul>
                </div>
                <p>
                  <strong>
                    满足以上权限只需要将 <code>PolicrBot</code> 提升为
                    <code>admin</code> 即可。
                  </strong>
                </p>
                <article
                  className="message is-warning"
                  style={articleMaiginStyle}
                >
                  <div className="message-body">
                    以下权限并非必要，但不赋予将限制机器人的后台管理功能
                  </div>
                </article>
                <div className="content">
                  <ul>
                    <li>通过链接邀请用户（Invite users via link）</li>
                  </ul>
                </div>
                <article className="message is-success">
                  <div className="message-body">
                    满足以上权限，机器人便可以全功能服务和工作
                  </div>
                </article>
                <article
                  className="message is-warning"
                  style={articleMaiginStyle}
                >
                  <div className="message-body">
                    如果某些中文包个性化翻译导致找不到权限，请自行脑补。或，
                    <strong>不限制任何权限</strong>
                  </div>
                </article>
              </div>
              <div className="section">
                <h3 className="title is-3">
                  <a name="commands" className="anchor"></a>
                  指令总览
                </h3>
                <hr />
                <table className="table is-bordered is-striped is-hoverable is-fullwidth">
                  <thead>
                    <tr>
                      <th align="left">名称</th>
                      <th align="left">描述</th>
                      <th align="center">类型</th>
                      <th align="center">详情</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td align="left">
                        <code>/settings</code>
                      </td>
                      <td align="left">主要设置项</td>
                      <td align="center">综合开关</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/ping</code>
                      </td>
                      <td align="left">存活测试</td>
                      <td align="center">状态</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/from</code>
                      </td>
                      <td align="left">设置来源调查</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/torture_time</code>
                      </td>
                      <td align="left">更新验证时间</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/custom</code>
                      </td>
                      <td align="left">定制验证方式</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/welcome</code>
                      </td>
                      <td align="left">设置欢迎消息</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/report</code>
                      </td>
                      <td align="left">举报垃圾内容</td>
                      <td align="center">功能</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/clean_mode</code>
                      </td>
                      <td align="left">干净模式设定</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/strict_mode</code>
                      </td>
                      <td align="left">严格模式设定</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/language</code>
                      </td>
                      <td align="left">切换工作语言</td>
                      <td align="center">设置</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/anti_service_msg</code>
                      </td>
                      <td align="left">删除服务消息</td>
                      <td align="center">综合开关</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/appeal</code>
                      </td>
                      <td align="left">申诉解除黑名单</td>
                      <td align="center">功能</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/voting_apply</code>
                      </td>
                      <td align="left">申请投票权</td>
                      <td align="center">权限</td>
                      <td align="center">略</td>
                    </tr>
                    <tr>
                      <td align="left">
                        <code>/global_rule_flags</code>
                      </td>
                      <td align="left">订阅全局屏蔽规则</td>
                      <td align="center">功能</td>
                      <td align="center">略</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div className="section">
                <h3 className="title is-3">
                  <a name="start" className="anchor"></a>
                  立即开始
                </h3>
                <hr />
                <p className="subtitle is-6">
                  首先需要进行一些基本设置，建议按照推荐来做。当然你在明白这些设置项的含义的情况也可以随心所欲
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /settings@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <div className="content">
                  <ul>
                    <li>
                      <p className="subtitle is-6">启用审核</p>
                      <p>
                        <strong>推荐</strong>
                        。验证用户，打击清真等子功能的总开关，它能避免被垃圾内容或危险帐号打扰。
                      </p>
                    </li>
                    <li>
                      <p className="subtitle is-6">信任管理</p>
                      <p>
                        <strong>推荐</strong>
                        。让管理员们有控制机器人的权力，帮忙干活。
                      </p>
                    </li>
                    <li>
                      <p className="subtitle is-6">私信设置</p>
                      <p>
                        <strong>推荐</strong>。
                        在群组中发送任何设置相关的指令，机器人会主动私聊发送设置菜单。有保护设置的私密性的作用，也避免了群聊中出现无关的设置过程消息。但设置不公开也意味着存在风险，因为无法得知哪个管理员设置过什么。
                      </p>
                    </li>
                    <li>
                      <p className="subtitle is-6">记录模式</p>
                      <p>
                        不推荐。默认行为会自动清理例如验证通过，解除限制一类的提示消息。此选项将保留所有中间消息，显得比较刷存在感。
                      </p>
                    </li>
                    <li>
                      <p className="subtitle is-6">容错模式</p>
                      <p>
                        推荐。验证错误发生时不武断封禁，继续多次验证以决定结果。在保证正确性的基础上更为人性化。
                        <strong>
                          但目前还不能支持自定义验证，因为无法添加多套验证问题
                        </strong>
                        。
                      </p>
                    </li>
                    <li>
                      <p className="subtitle is-6">静音模式</p>
                      <p>
                        <strong>推荐</strong>。
                        大部分与其他人无关的消息将以无声通知的方式发送，例如验证消息。因为验证是瞬间行为，即便没有声音通知也会被看到。所以理论上不会导致新群成员对验证的忽视。
                      </p>
                    </li>
                  </ul>
                </div>
                <article className="message is-danger">
                  <div className="message-body">
                    如果不信任管理员，则管理员没有权限使用指令调整任何设置。
                  </div>
                </article>
                <p className="subtitle is-6">
                  有些人反应很迟钝，默认验证时间<code>55</code>秒可能有点短
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /torture_time@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <article className="message is-danger">
                  <div className="message-body">
                    和很多机器人使用方式不同，请使用回复进行设置，而不是发送公屏消息。
                  </div>
                </article>
                <article className="message is-success">
                  <div className="message-body">
                    允许在完成设置以后编辑消息，这是会生效的。编辑设置的回复能再次更新相关设置。
                  </div>
                </article>
                <p className="subtitle is-6">
                  向新成员发送欢迎消息，带上你群规或帮助～
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /welcome@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <article className="message is-warning">
                  <div className="message-body">
                    请不要使用其它欢迎机器人。因为它们不会读取验证结果，只能无脑发送欢迎，哪怕没有通过验证。
                  </div>
                </article>
                <p className="subtitle is-6">
                  群组正在四处宣传，很需要知晓入群成员来自何处
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /from@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <p className="subtitle is-6">
                  怎么回事？机器人不干活嘞，检测它是否还活着
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /ping@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <p className="subtitle is-6">
                  默认的验证方式太简单了，我想调整一下
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /custom@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <p className="subtitle is-6">
                  有人发广告？看我举报它，让它进入黑名单！
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /report@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <article className="message is-danger">
                  <div className="message-body">
                    注意了，举报指令需要回复在被举报的消息上。
                  </div>
                </article>
                <p className="subtitle is-6">
                  群组太冷门了，没人聊天。以至于总被验证失败的消息刷屏。能不能自动清理？
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /clean_mode@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <p className="subtitle is-6">
                  想保留系统消息？哦不，我想保留入群消息，但不保留退群消息！
                </p>
                <figure className="highlight">
                  <pre>
                    <code className="language-bash" data-lang="bash">
                      /anti_service_msg@{BOT_USERNAME}
                    </code>
                  </pre>
                </figure>
                <article className="message is-warning">
                  <div className="message-body">
                    请不要使用其它删除服务消息的机器人（例如
                    @AntiServiceMessageBot）。因为它们会影响依赖入群消息的验证功能。通过本机器人自带的相关能力，将会在适当的时机下删除入群消息，而不是无脑的立即删除。
                  </div>
                </article>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
